package main

import (
	"fmt"
	"log"
	"strings"
	"scrapemd/smd"
	"github.com/xanzy/go-gitlab"
)

const (
	gitLabBaseURL = "https://gitlab.com" //
	groupID = 000000000 /// sylva project group ID
	fileextension = "md"
)

func main() {

	// INSERT "YOUR_ACCESS_TOKEN" GitLab
	gitLabToken := ""

	client, err := gitlab.NewClient(gitLabToken, gitlab.WithBaseURL(gitLabBaseURL))
	if err != nil {
		log.Fatal(err)
	}

	opt := &gitlab.ListGroupProjectsOptions{}
	projects, _, err := client.Groups.ListGroupProjects(groupID, opt)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Projects in group (ID: %d):\n", groupID)
	for _, project := range projects {
		//fmt.Printf("- %s (%s)\n", project.Name, project.SSHURLToRepo)
		smd.Printmonmd(extractGitURL(project.SSHURLToRepo),fileextension)
		//fmt.Printf("---- URL is %s \n\n", extractGitURL(project.SSHURLToRepo))
	}
	
	printGroup(client, groupID, 0)
}

func printGroup(client *gitlab.Client, groupID int, depth int) {
	indent := ""
	for i := 0; i < depth; i++ {
		indent += "  "
	}

	group, _, err := client.Groups.GetGroup(groupID, &gitlab.GetGroupOptions{})
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("%sGroup: %s (ID: %d)\n", indent, group.Name, group.ID)

	opt := &gitlab.ListGroupProjectsOptions{}
	projects, _, err := client.Groups.ListGroupProjects(groupID, opt)
	if err != nil {
		log.Fatal(err)
	}

	// fmt.Printf("%s  Projects:\n", indent)
	for _, project := range projects {
		//fmt.Printf("%s    - %s (%s)\n", indent, project.Name, project.SSHURLToRepo)
		smd.Printmonmd(extractGitURL(project.SSHURLToRepo),fileextension)
		fmt.Printf("---- URL is %s \n", extractGitURL(project.SSHURLToRepo))
	}

	// Récupérer tous les groupes
	allGroups, _, err := client.Groups.ListGroups(nil)
	if err != nil {
		log.Fatal(err)
	}

	// Gives all the groups for given groupID 
	subgroups := filterSubgroups(allGroups, groupID)

	// Get all sub groups
	for _, subgroup := range subgroups {
		printGroup(client, subgroup.ID, depth+1)
	}
}

func filterSubgroups(groups []*gitlab.Group, parentID int) []*gitlab.Group {
	var result []*gitlab.Group

	for _, group := range groups {
		if group.ParentID == parentID {
			result = append(result, group)
		}
	}

	return result
}

func extractGitURL(sshURL string) (string) {
	// could be improved !!
	gitURL := strings.Replace(sshURL, "git@", "https://", 1)
	gitURL = strings.Replace(gitURL, ".com:", ".com/", 1)           
	//fmt.Printf("gitURL %s \n", gitURL)
	return gitURL
}
