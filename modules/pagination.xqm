xquery version "3.0";

module namespace pagination="http://hra.uni-heidelberg.de/ns/hra-csv2vra/pagination";
import module namespace templates="http://exist-db.org/xquery/templates" ;

declare 
    %templates:default("maxpages", 3)
function pagination:show($count as xs:integer, $active as xs:integer, $maxpages as xs:integer, $node-prefix as xs:string, $ajax-function as xs:string) {
    <ul class="pagination pagination-sm">
        <li class="{$node-prefix}" id="{$node-prefix}last" onclick="{$ajax-function}(1, '{$node-prefix}');"><a href="#">&#124;&lt;</a></li>
    {
        (: disable "previous" if first page active :)
        if ($active = 1) then 
                <li class="{$node-prefix} disabled" id="{$node-prefix}first"><a href="#">&lt;</a></li>
            else
                <li class="{$node-prefix}" onclick="{$ajax-function}({$active - 1}, '{$node-prefix}');" id="{$node-prefix}first"><a href="#">&lt;</a></li>
    }
    {
        <li><a href="#">[...]</a></li>   
    }
    {
        let $start := max( (1, $active - $maxpages) ) 
        let $end := min( ($count, $active + $maxpages) ) 
        for $i in $start to $end return
            if ($i = $active) then
                <li class="{$node-prefix} active" id="{$node-prefix}{$i}" onclick="{$ajax-function}({$i}, '{$node-prefix}');"><a href="#">{$i}</a></li>
            else
                <li class="{$node-prefix}" id="{$node-prefix}{$i}" onclick="{$ajax-function}({$i},'{$node-prefix}');"><a href="#">{$i}</a></li>
    }
    {
        <li><a href="#">[...]</a></li>   
    }
    {
        (: disable "next" if last page active :)
        if ($active = $count) then 
                <li class="{$node-prefix} disabled" id="{$node-prefix}last"><a href="#">&gt;</a></li>
            else
                <li class="{$node-prefix}" id="{$node-prefix}last" onclick="{$ajax-function}({$active + 1}, '{$node-prefix}');"><a href="#">&gt;</a></li>
    }
        <li class="{$node-prefix}" id="{$node-prefix}last" onclick="{$ajax-function}({$count}, '{$node-prefix}');"><a href="#">&gt;&#124;</a></li>
    </ul>
};