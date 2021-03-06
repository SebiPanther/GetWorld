#!/bin/bash
#Crawler zum abrufen der #rC3
IFS=$'\n'
UrlsOrgSource="https://gist.githubusercontent.com/MichaelKreil/e967f4b91b3c147fc8b414f88bde9dae/raw/5ce26dccc0275894c6ce77266bd8251f52700533/rc3world_urls_2020-12-28-23-00"
UrlsFile="Urls.txt"
UrlsFileTmp="UrlsTmp.txt"
UrlsFileNew="UrlsNew.txt"
ProtocolPrefix="https://"


function AnalyseJson {
	local jsonFull=$1
	local file=$(basename $jsonFull)
	local path=$(dirname $jsonFull)
	
	echo -n Analyse Json $jsonFull...
	local tilesets=$(jq -r .tilesets[].image $jsonFull)
	for tile in $tilesets
	do
		echo $ProtocolPrefix$path/$tile >> $UrlsFileTmp
	done
	local countTilesets=$(echo -n "$tilesets" | wc -l)
	echo -n $countTilesets Tilesets found!...
		
	local sounds=$(jq -r ".layers[]|select(.properties != null)|.properties[]|select(.name==\"playAudio\",.name==\"playAudioLoop\").value" $jsonFull)
	for sound in $sounds
	do
		echo $ProtocolPrefix$path/$tile >> $UrlsFileTmp
	done
	local countSounds=$(echo -n "$sounds" | wc -l)
	echo -n $countSounds Sounds found!...
	
	local maps=$(jq -r ".layers[]|select(.properties != null)|.properties[]|select(.name==\"exitUrl\",.name==\"exitSceneUrl\").value" $jsonFull)
	local count=0
	for mapFull in $maps
	do
		local map=$(echo $mapFull | cut -f1 -d"#")
		if [[ "$map" == https\:\/\/* ]]
		then
			echo $map >> $UrlsFileTmp
		else
			echo $ProtocolPrefix$path/$map >> $UrlsFileTmp
		fi
	done
	local countMaps=$(echo -n "$maps" | wc -l)
	echo $countMaps Maps found!
}  
#Download base URLs if are not available
if [ ! -f $UrlsFile ]; then
    echo $UrlsFile not found - download it now!
	wget -O $UrlsFile -nv -x -nc $UrlsOrgSource
fi

echo Download know files from File $UrlsFile!
wget --timeout=3 --tries=3 --no-check-certificate --retry-connrefused -nc -v -x -i $UrlsFile #-w 3 -N

#Run Analyse of the downloaded json files
echo Analyse downloaded Files!
echo -n > $UrlsFileTmp
jsons=$(find */ -name "*.json")
for json in $jsons
do
	AnalyseJson $json
done

#Distinct Urls in Analysed file
echo Find distinct Urls!
uniq $UrlsFileTmp > $UrlsFileNew

echo All done - check $UrlsFileNew