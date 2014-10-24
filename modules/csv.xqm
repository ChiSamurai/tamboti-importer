xquery version "3.0";

module namespace csv="http://hra.uni-heidelberg.de/ns/hra-csv2vra/csv";

import module namespace unzip = "http://joewiz.org/ns/xquery/unzip";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://hra.uni-heidelberg.de/ns/hra-csv2vra/config" at "config.xqm";

(:declare default element namespace "http://schemas.openxmlformats.org/package/2006/content-types";:)


declare
(:    %templates:wrap:)
function csv:read-csv($filename as xs:string) {
    let $csv := file:read($filename)
(:    let $lines := tokenize($csv, "\n"):)
(:    let $head := tokenize($lines(1), ','):)
(:    let $body := remove($lines, 1):)
(:    return :)
(:      <result>:)
(:            {:)
(:            for $line in $body:)
(:            let $fields := tokenize($line, ';'):)
(:            return:)
(:                <line>:)
(:                    {:)
(:                        for $key at $pos in $head:)
(:                        let $value := $fields[$pos]:)
(:                        return:)
(:                            element { normalize-space(replace($key,' ','_')) } { $value }:)
(:                    }:)
(:                </line>:)
(:            }:)
(:        </result>:)
    return
        <result>
            {$csv}
        </result>
    
};


(:for $csv-file in xmldb:get-child-resources($config:data-root):)
(:    return:)
(:        util:binary-to-string(util:binary-doc($config:data-root || "/" || $csv-file), "UTF-8"):)
(:        :)
(:csv:read-csv("/db/apps/hra-viewer/"):)

