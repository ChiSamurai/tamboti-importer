xquery version "3.0";

module namespace img="http://hra.uni-heidelberg.de/ns/hra-csv2vra/img";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
import module namespace functx="http://www.functx.com";
import module namespace content="http://exist-db.org/xquery/contentextraction" at "java:org.exist.contentextraction.xquery.ContentExtractionModule";


declare function img:getImageData($path as xs:string, $binaryImageFile as xs:string) {
(:    let $fileName := "i_0042bf58-3239-466f-a68e-fc79496f3f74.jpg":)
    let $imageBinary := util:binary-doc($path || "/" || $binaryImageFile)
    return 
        if (empty($imageBinary))then 
            false()
        else
            let $metadata := contentextraction:get-metadata($imageBinary)
            return 
                <image>
                    <filename>
                        {
                            $binaryImageFile
                        }
                    </filename>
                    <width>
                        {
                            let $width := functx:get-matches(data($metadata//xhtml:meta[@name="Exif Image Width"]/@content), "^\d+")[1]
                            return $width
                        }
                    </width>
                    <height>
                        {
                            let $height := functx:get-matches(data($metadata//xhtml:meta[@name="Exif Image Height"]/@content), "^\d+")[1]
                            return $height
                        }
                    </height>
                    <creationDate>
                        {
                            data($metadata//xhtml:meta[@name="meta:creation-date"]/@content)
                        }
                    </creationDate>
                    <resolutionInfo>
                        {
                            let $resInfo := functx:get-matches(data($metadata//xhtml:meta[@name="Resolution Info"]/@content), "^\d+[\.]\d+x\d+[\.]\d")[1]
                            return $resInfo
                        }
                    </resolutionInfo>
                    <bitDepth>
                        {
                            let $spp := xs:float(data($metadata//xhtml:meta[@name="tiff:SamplesPerPixel"]/@content))
                            let $bps := xs:float(data($metadata//xhtml:meta[@name="tiff:BitsPerSample"]/@content))
                            return xs:float($spp * $bps)
                        }
                    </bitDepth>
                    <filesize>
                        {
                            xmldb:size($path,  $binaryImageFile)
                        }
                    </filesize>
                    <fullMetadata>
                            {
                                $metadata
        (:                            image:get-metadata($imageBinary, false()) :)
                            }
                    </fullMetadata>
                </image>
};