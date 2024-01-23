# SPI_website

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/ReseauBiodiversiteQuebec/SPI_website/build.yml)
![Static Badge](https://img.shields.io/badge/development-actif-blue)

Ce répertoire contient le site web qui présente les démarches et résultats du calcul de l'[indicateur SPI](https://geobon.org/ebvs/indicators/species-protection-index/) pour le Québec.

## Utilisation

### Histoire de biodiversité

Les résultats sont présentés sour forme d'une histoire de la biodiversité à l'intension d'un publique large. Cette page présente dans la forme d'une communication appuyée par des visualisation l'état de la protection des habitats favorables à la présence de plusieurs espèces du Québec.

### Indicateur de protection des espèces

Cet onglet contient la description, la méthodologie et les résultats des calculs du SPI pour diverses approches.

- Occurences
- Aires de distribution
- SDM - INLA

### About

À être développé...


## Prévisionner le site web en local 

1. Clôner localement le répertoire

  ```bash
git clone https://github.com/ReseauBiodiversiteQuebec/SPI_website.git
```
  
3. Installer les dépendances et construire l'environnement virtuel. La gestion des dépendances est opérée par le package `renv`.

```R
renv::restore()
```

2. Construire le site web

```R
quarto::preview()
```

## Structure du Projet

- `/src`: Code source
- `/results`: Résultats
- `results/img`: visualisations
- `*.qmd`: Documentation

## Contribuer aux travaux

Le développement de ce répertoire se fait sur des branches parallèles. La branche `main` est réservée pour la version publiée du site web. Les utilisateurs qui désirent ajouter ou modifier des composantes du répertoire sont priés de créer une branche pour apporter leurs modifications et de soumettre leur proposition sous forme de pull-request.

Pour ajouter des dépendances au répertoire, il faut d'abord installer les packages, puis mettre à jour l'environnement à l'aire de la commande `renv::snapshot()`.

## Licence

Ce projet est sous licence MIT. Consultez le fichier [LICENSE]() pour plus d'informations.
