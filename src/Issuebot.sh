#!/bin/bash

javac IssueHandler2.java

#Uncomment to just run the java file
#java IssueHandler2 

#build a jar file for ruby
jar cvfe IssueHandler2.jar IssueHandler2 *.class

#execute jar file
java -jar IssueHandler2.jar

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml config.yaml)

#tests for config files
#echo $Github_IssueReport_title
#echo $Github_IssueReport_body
#echo $Github_IssueReport_bug
#echo $Github_UserInfo_repoOwner
#echo $Github_UserInfo_repoName
#echo $Github_UserInfo_token

curl -i -H "Authorization: token $Github_UserInfo_token" -d \
       "{ \"title\": \"$Github_IssueReport_title \", \"body\": \"$Github_IssueReport_body\", \"labels\": [\"design\"]}" \
       https://api.github.com/repos/$Github_UserInfo_repoOwner/$Github_UserInfo_repoName/issues \
