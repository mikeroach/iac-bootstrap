#!/bin/bash

# The Google Project Factory module includes a helper script to create a service
# account in the seed project (created outside the Factory). To run the correct
# helper script path via our gcp-seed-project module's provisioner, I invoke
# get-project-factory-version.sh as a Terraform external data source to clumsily
# determines which version of the Project Factory module we're using. I couldn't
# figure out how to get something like $module.project-factory.version working
# from a *different module*, and decided these shenanigans were better than
# duplicating a hardcoded variable value (even though I ended up repeating 
# myself elsewhere anyway).
# See: https://github.com/terraform-google-modules/terraform-google-project-factory#script-helper 

set -e
VERSION=`grep "// Key for get-project-factory-version.sh (don't change or remove this MAGIC comment\!)" main.tf | awk -F // '{print $1}' | awk '{print $NF}' | sed -e 's/\"//g'`
jq -n --arg version "$VERSION" '{"version":$version}'
