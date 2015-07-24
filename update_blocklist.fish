#!/usr/bin/fish
#   Fetch fresh torrent blocklists from iblocklist
#   Inspired by (and expressions stolen from) https://raw.githubusercontent.com/cinus/iblocklist/master/get_lists.sh

set package_home    (dirname (status -f))
set __log_file      "$package_home/blocklistd.log"

#require_logging
. $package_home/logging.fish

function http_get -a url
    info Downloading $url
    curl -s $url
end

function ibl_filter_ids -a host
    grep $host | awk '{ print $8 }' | awk -F '=' '{ print $2 }' | sed 's/.//;s/.$//'
end 

begin
    set LIST_FMT            "blocklist_%s.%s"

    set list_store          "$package_home/blocklists"
    set blocklist_directory "https://www.iblocklist.com/lists.php"
    set blocklist_source    "http://list.iblocklist.com"
    set request_options     "fileformat=p2p&archiveformat=gz"

    set merge_target        "$package_home/"(printf $LIST_FMT (date +'%Y%m%d') "gz")
    set latest_symlink      "$package_home/"(printf $LIST_FMT latest "gz")
    
    set script_run_date     (date +%s)  # Unix time used to check modification delta of blocklists
    set max_cache_age       432000      # 5 days. 
    set stale_age           2592000     # 1 month. The blocklist is considered dead if it goes un-updated this long

    debug script_run_date is $script_run_date

    if [ ! -d $list_store ]
        mkdir -p $list_store
    end

    # Handle list downloads and caching
    
    set list_ids    (http_get $blocklist_directory | ibl_filter_ids $blocklist_source)
    info (count $list_ids) list IDs downloaded
    for id in $list_ids
        set list_file "$list_store/"(printf $LIST_FMT $id "gz")

        function fetch_list -S
            info Downloading list $id to $list_file
            if wget "$blocklist_source/?list=$id&$request_options" -O $list_file ^/dev/null
                touch $list_file # server mod date not wanted
            else
                error Could not download $list_file due to wget $status
            end
        end

        if [ -f $list_file ]
            # Check modification time
            set mod_date (stat -c '%Y' $list_file)
            set mod_delta (echo "$script_run_date - $mod_date" | bc)
            if [ $mod_delta -gt $max_cache_age ]
                info redownloading $id as it is too old
                rm $list_file
                fetch_list 
            else
                info $list_file is up to date
            end
        else
            fetch_list
        end
    end

    # Process lists

    set list_files  (eval "ls "(printf $list_store/$LIST_FMT '*' 'gz'))

    # Clean stale lists
    
    info Checking for stale lists

    for list_file in $list_files
        set mod_date (stat -c '%Y' $list_file)
        set mod_delta (echo "$script_run_date - $mod_date" | bc)
        if [ $mod_delta -gt $stale_age ]
            info removing stale list at $list_file
            rm $list_file
        end
    end

    info Merging (count $list_files) lists in to $merge_target
    gzip -cd $list_files | sort -t ':' -k2 -u | sed -r '/^#/d;/^$/d' | gzip --best - > $merge_target
    info Making $merge_target world-readable
    chmod a+r $merge_target

    if [ -e $latest_symlink ]
        warn removing $latest_symlink
        
        if [ -L $latest_symlink ]
            rm $latest_symlink
        else
            error $latest_symlink EXISTS AND IS NOT A SYMLINK. PLEASE REMOVE IT!
        end
    end
	
    if [ ! -e $latest_symlink ]
        info Linking $latest_symlink to $merge_target
        ln -s $merge_target $latest_symlink 
    else
        warn Not linking $latest_symlink because it exists
    end


    info Final size is (du -sch $merge_target | tail -n 1 | cut -f1)
end
