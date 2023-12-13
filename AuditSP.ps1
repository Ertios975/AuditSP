$dossierCible = "?:\CIBLE"
$fichierSortie = "LOG.txt"

function test-SharepointError($dossierCible) {
    $TabFichier = [System.Collections.ArrayList]::new()
    $TabDossier = [System.Collections.ArrayList]::new()
    $listeCaracteresInterdits = @('<', '>', ':', '"', '|', '/', '\', '`*')
    $listeExtensionsInterdites = @('exe', 'dll', 'bat', 'ps1','lock')
    $listeNomsInterdits = @('~$', 'CON', 'PRN', 'AUX', 'NUL', 'COM0', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT0','LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7', 'LPT8', 'LPT9', '_vti_', 'desktop.ini')
    $nombreElements = 0
    $problemeElementsParDossier =0

    $RetourDossier = Get-ChildItem -Path $dossierCible -Recurse

    ######
    # Recherche des fichiers avec des caractères, des noms et des extension interdits
    function Test-VerifierCaracteresInterdits($nomFichier, $listeCaracteresInterdits) {
        $probleme = $false
        foreach ($caractere in $listeCaracteresInterdits) {
            if ($nomFichier -like "*$caractere*") {
                $TabFichier.Add("Avertissement: Le caractère '$caractere' est présent dans le nom du fichier '$nomFichier'")
                $probleme = $true
            }
        }
        return $probleme
    }

    function Test-VerifierExtensionInterdite($nomFichier, $listeExtensionsInterdites) {
        $probleme = $false
        $extension = [System.IO.Path]::GetExtension($nomFichier).TrimStart('.')
        if ($listeExtensionsInterdites -contains $extension) {
            $TabFichier.Add("Avertissement: L'extension '$extension' du fichier '$nomFichier' est interdite.")
            $probleme = $true
        }
        return $probleme
    }

    function Test-VerifierNomsInterdits($nomFichier, $listeNomsInterdits) {
        $probleme = $false
        foreach ($nom in $listeNomsInterdits) {
            if ($nomFichier -like "*$nom*") {
                $TabFichier.Add("Avertissement: Le nom '$nom' de l'élément '$nomFichier' est interdits.")
                $probleme = $true
            }
        }
        return $probleme
    }

    function Show-SharepointError {
        $RetourDossier | ForEach-Object {
            if ($_ -is [System.IO.FileInfo]) {
                $nombreElements++
                $longueurChemin = $_.FullName.Length
                $longueurNomFichier = $_.Name.Length
                $nombreTotalCaracteres = $longueurChemin + $longueurNomFichier

                $problemeCaracteres = Test-VerifierCaracteresInterdits $_.Name $listeCaracteresInterdits
                $problemeExtension = Test-VerifierExtensionInterdite $_.Name $listeExtensionsInterdites
                $problemeNoms = Test-VerifierNomsInterdits $_.Name $listeNomsInterdits

                if ($problemeCaracteres -or $problemeExtension) {
                    $nombreElementsProblematiques ++
                    $TabFichier.Add("Chemin: $($_.FullName)")
                    $TabFichier.Add("-------------------------")
                }
                if ($longueurNomFichier -gt 128) {
                    $nombreElementsProblematiques ++
                    $TabFichier.Add("Chemin: $($_.FullName)")
                    $TabFichier.Add("Longueur du nom du fichier: $longueurNomFichier")
                    $TabFichier.Add("-------------------------")

                }
                if ($nombreTotalCaracteres -gt 260) {
                    $nombreElementsProblematiques ++
                    $TabFichier.Add("Chemin: $($_.FullName)")
                    $TabFichier.Add("Nombre total de caractères: $nombreTotalCaracteres")
                    $TabFichier.Add("-------------------------")
                }
                if ($problemeNoms) {
                    $nombreElementsProblematiques ++
                    $TabFichier.Add("Chemin: $($_.FullName)")
                    $TabFichier.Add("-------------------------")
                }
            }
        }
        Write-Host "Nombre total d'éléments scannés: $nombreElements"
        Write-Host "Nombre d'éléments problématiques: $nombreElementsProblematiques`n"
        Write-Host "Liste des fichiers problématiques: `n`n$($TabFichier -join "`n`n")"        
    }

    # Recherche des dossiers avec plus de 200 000 éléments
    function Get-NbElementsParDossier {
        $probleme = $false

        $nbElements = (Get-ChildItem -Path $dossier -Recurse | Measure-Object).Count
        if ($nbElements -ge 2000) {
            $TabDossier.Add(" - Le dossier '$dossier'") | Out-Null
            $TabDossier.Add("   comprend '$nbElements' éléments") | Out-Null
            $probleme = $true          
        }
        return $probleme
    }

    function Show-NbElementsParDossier {
            $RetourDossier | ForEach-Object {
            if ($_.PSIsContainer) {
                $dossier = $_.FullName
                $nombreElements++
                $problemeElements = Get-NbElementsParDossier $_.Name $dossier

                if ($problemeElements) {
                    $problemeElementsParDossier ++
                }
            }
        }
        Write-Host "Nombre total de dossiers scannés: $nombreElements" # Donne tous les éléments et pas les dossiers
        Write-Host "Nombre de dossiers comprenant plus de 200 000 éléments : $problemeElementsParDossier`n"
        Write-Host "Liste des dossiers comprenant plus de 200 000 éléments : `n$($TabDossier -join "`n")"
    }

    # Création fichier de sortie

    if (!(Test-Path "$fichierSortie")) {
        New-Item -Path $fichierSortie -ItemType File -Force
    }

    # Ecriture du fichier

    Write-Host "`n`n"
    Write-Host "Recherche des chaînes de caractères, extensions ou nom pouvant poser des problèmes"
    Show-SharepointError 
    Write-Host "`n`n"
    Write-Host "Recherche des dossiers de plus de 200 000 fichiers`n"
    Show-NbElementsParDossier
}

test-SharepointError $dossierCible 6>> $fichierSortie
