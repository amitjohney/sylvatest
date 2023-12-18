package smd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/src-d/go-git.v4"
)

func Printmonmd(gitLabURL string, fileextension string )(){
	destinationPath := "./my_tmp_clone"
	err := DeleteFolder(destinationPath)

	// Vérifier si le répertoire de destination existe
	if _, err := os.Stat(destinationPath); os.IsNotExist(err) {
		// Clone project
		_, err := git.PlainClone(destinationPath, false, &git.CloneOptions{
			URL:      gitLabURL,			
		})

		if err != nil {
			fmt.Println("Clone issue:", err)
			return
		}

		//fmt.Println("Clone done")
	} else {
		fmt.Println("The folder is exiting")
	}

	// Appel à la fonction pour récupérer les URL complètes des fichiers MD dans la branche principale
	urls, err := retrieveMarkdownURLs(destinationPath, gitLabURL,fileextension )
	if err != nil {
		fmt.Println("Erreur lors de la récupération des URL des fichiers MD:", err)
	} else {
		// Afficher les URL complètes des fichiers MD
		fmt.Printf("URLs found for %s extension : \n", fileextension )
		for _, url := range urls {
			fmt.Println("#####", url)
		}
		fmt.Println()
	}
}

//Remove temp folder
func DeleteFolder(destinationPath string) (err error) {
	err = os.RemoveAll(destinationPath)
	if err != nil {
		fmt.Println("Erreur lors de la suppression du répertoire:", err)
	} 
	return err
}

// Fonction pour récupérer les URL complètes des fichiers MD
func retrieveMarkdownURLs(rootPath, gitLabURL string, fileextension string ) ([]string, error) {
	var urls []string

	// Supprimer ".git" de la fin de l'URL si présent
	gitLabURL = strings.TrimSuffix(gitLabURL, ".git")

	repository, err := git.PlainOpen(rootPath)
	if err != nil {
		return nil, err
	}

	// Récupérer la référence HEAD pour obtenir la branche actuelle
	headRef, err := repository.Head()
	if err != nil {
		return nil, err
	}

	// filepath.Walk for all folders
	err = filepath.Walk(rootPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Vérifier si le fichier a l'extension .md
		if strings.HasSuffix(info.Name(), fileextension) {
			// Build a full URL name for a given Filename and expected fileExtension
			relativePath, err := filepath.Rel(rootPath, path)
			if err != nil {
				return err
			}
			url := strings.ReplaceAll(filepath.ToSlash(relativePath), string(filepath.Separator), "/")
			// Construire l'URL complète sans le nom du répertoire et .git
			fullPath := fmt.Sprintf("%s/blob/%s/%s", gitLabURL, headRef.Name().Short(), url)

			// append new url in urls list
			urls = append(urls, fullPath)
		}

		return nil
	})

	return urls, err
}
