package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
)

type Asset struct {
	Name               string `json:"name"`
	BrowserDownloadUrl string `json:"browser_download_url"`
}

type Release struct {
	Assets  []Asset `json:"assets"`
	TagName string  `json:"tag_name"`
}

func main() {
	resp, err := http.Get("https://api.github.com/repos/cue-lang/cue/releases/latest")
	if err != nil {
		fmt.Printf("The HTTP request failed with error %s\n", err)
		return
	}

	data, _ := io.ReadAll(resp.Body)
	var release Release
	json.Unmarshal(data, &release)

	var checksumUrl string
	for _, asset := range release.Assets {
		if asset.Name == "checksums.txt" {
			checksumUrl = asset.BrowserDownloadUrl
			break
		}
	}
	resp, err = http.Get(checksumUrl)
	if err != nil {
		fmt.Printf("The HTTP request failed with error %s\n", err)
		return
	}

	checksumData, _ := io.ReadAll(resp.Body)
	checksumLines := strings.Split(string(checksumData), "\n")
	checksumMap := make(map[string]string)
	for _, line := range checksumLines {
		parts := strings.Fields(line)
		if len(parts) == 2 {
			checksumMap[parts[1]] = parts[0]
		}
	}
	fmt.Printf("Checksum map: %v\n", checksumMap)

	// Create a map to hold the final output
	finalMap := make(map[string]map[string]string)

	// Iterate over the checksum map
	for filename, checksum := range checksumMap {
		// Parse the OS and architecture from the filename
		parts := strings.Split(filename, "_")
		os := parts[2]
		arch := strings.Split(parts[3], ".")[0]
		// Create a key for the OS and architecture
		key := fmt.Sprintf("struct(os = \"%s\", arch = \"%s\")", os, arch)
		// Add the checksum to the final map
		if _, ok := finalMap[release.TagName]; !ok {
			finalMap[release.TagName] = make(map[string]string)
		}
		finalMap[release.TagName][key] = checksum
	}

	fmt.Printf("Final map: %v\n", finalMap)

	// Create a string builder to hold the final output
	var builder strings.Builder

	// Iterate over the final map
	for version, checksums := range finalMap {
		builder.WriteString(fmt.Sprintf("\"%s\": {\n", version))
		for key, checksum := range checksums {
			builder.WriteString(fmt.Sprintf("    %s: \"%s\",\n", key, checksum))
		}
		builder.WriteString("},\n")
	}

	fmt.Printf("Final output: \n%s", builder.String())
}
