---
title: "Feuille de Route"
meta_title: "Feuille de route des prochaines modifications de LegitDAO"
description: "Ce document explique la feuille de route des prochaines modifications de LegitDAO"
draft: false
---
{{< toc >}}

LegitDAO se lance dans une aventure passionnante pour créer une organisation autonome décentralisée (DAO) avec un écosystème robuste. Notre feuille de route décrit les étapes que nous allons suivre pour développer des composants essentiels qui permettront aux utilisateurs de revendiquer des tokens, d'utiliser des contrats intelligents et de favoriser l'engagement communautaire. Dans cet article, nous allons élaborer nos plans, en les décomposant en phases distinctes afin de rendre notre vision plus claire et accessible.

## Date limite des étapes
Notre objectif est de finaliser la version alpha de cette première phase dans un délai de quatre (4) à six (6) mois. Au fur et à mesure que nous complétons chaque section, nous téléchargerons le code sur notre dépôt GitHub. De plus, nous mettrons à jour le [changelog](/fr/changelog) et publierons un [article de blog](/fr/blog) détaillant notre processus de développement.

## Réclamation de Tokens et Contrats Intelligents
Dans notre prochaine mise à jour, nous introduirons le mécanisme permettant aux individus de revendiquer leurs tokens au sein de l'écosystème LegitDAO. Ces tokens tireront parti de contrats intelligents construits sur la BNB Chain, garantissant des transactions sécurisées et efficaces. Pour faciliter cela, nous créerons trois contrats intelligents principaux : Fondateur, DAO et Monnaie. Chaque contrat aura un objectif unique, contribuant à la fonctionnalité globale de l'écosystème.

De plus, nous développerons un contrat intelligent d'affiliation qui permettra aux utilisateurs de référer d'autres personnes à notre projet. Cette fonctionnalité inclura le déploiement initial du contrat intelligent d'affiliation, permettant un arbre de référence négociable qui pourra récompenser ceux qui contribuent à la croissance de notre communauté. Cette approche innovante encourage non seulement l'engagement, mais crée également un environnement de soutien pour tous les participants.

## Développement de l'Interpréteur de Bytecode
Après avoir établi notre cadre de tokens, nous nous concentrerons sur la création d'un interpréteur de bytecode. Ce composant crucial exécutera la logique au sein de notre écosystème, utilisant des entiers non signés pour comprendre les commandes. L'interpréteur de bytecode servira de colonne vertébrale pour les futures fonctionnalités, nous permettant de traiter les commandes de manière efficace et précise.

## Matcher de Grammaire et Arbre de Syntaxe Abstraite (AST)
Ensuite, nous introduirons un matcher de grammaire qui facilitera la création d'un Arbre de Syntaxe Abstraite (AST) basé sur des schémas de grammaire et des données d'entrée. Cette étape est essentielle pour analyser et comprendre les structures que nous rencontrerons au sein de notre écosystème.

Suite à la mise en œuvre du matcher de grammaire, nous développerons un sélecteur. Le sélecteur utilisera des définitions de schéma pour récupérer facilement des données de l'AST. En utilisant ces outils, nous visons à rationaliser les processus de récupération de données, améliorant ainsi l'efficacité globale de notre écosystème.

## Développement de la Machine Virtuelle
Pour aller plus loin dans nos fonctionnalités, nous créerons une grammaire pour la machine virtuelle (MV). Cette MV sera construite à l'aide du matcher de grammaire et du sélecteur, permettant un parsing efficace de la grammaire d'entrée en bytecode. Ce bytecode sera ensuite interprété par notre interpréteur de bytecode, permettant l'exécution dynamique des commandes.

## Système de Base de Données Graphe
Le prochain composant majeur de notre feuille de route implique la création d'un système de base de données graphe. Cette base de données utilisera la grammaire pour établir des liens et des connexions entre divers points de données. En analysant les instructions avec notre matcher de grammaire et en récupérant des données pertinentes à l'aide du sélecteur, nous compilerons ces instructions en bytecode pour interprétation.

Dans le cadre de cette phase, nous modifierons l'interpréteur de bytecode pour permettre l'écriture atomique de données sur le disque. Cette amélioration facilitera la mise en œuvre d'un système de transactions qui représente avec précision l'état de la base de données. Les utilisateurs auront la possibilité de naviguer à travers les différents états de la base de données, récupérant les données selon les besoins.

## Blockchain personnalisée
Pour soutenir notre monnaie, nous développerons une blockchain qui contiendra également de la monnaie liée à notre contrat intelligent de monnaie sur la BNB Chain. Chaque transaction sur cette blockchain incorporera un hachage de 64 octets représentant des octets d'instructions que notre interpréteur de bytecode pourra interpréter. De plus, nous créerons un pont entre cette blockchain et la BNB Chain pour garantir des transferts atomiques, assurant une interaction fluide entre les deux réseaux.

## Développement du Marché NFT
En tandem avec la base de données graphe, nous établirons un marché NFT de code. Ce marché utilisera notre base de données graphe pour le stockage et notre blockchain pour créer de nouveaux NFT. Les utilisateurs pourront acheter et vendre des NFT en utilisant la monnaie associée à cette blockchain, favorisant un espace communautaire interactif.

Alors que nous développons davantage notre interpréteur de bytecode, nous introduirons des opérations vectorielles. En mettant à jour notre machine virtuelle pour accueillir de nouvelles instructions, nous pourrons implémenter des fonctionnalités qui associent des vecteurs similaires au sein de notre base de données graphe. Cela cultivera une communauté de mineurs responsables du traitement des données, de la création d'arbres de hachage et de l'établissement de connexions entre des points de données similaires.

## Base de Données de Contenu et Modèle Linguistique
Notre feuille de route inclut également la création d'une base de données de contenu multilingue. Cette base de données permettra la soumission, le filtrage et la modération du contenu par notre communauté, garantissant des normes de haute qualité. Les mineurs auront la possibilité de traiter ces données, créant des liens significatifs qui contribuent au développement d'un grand modèle linguistique (LLM) et d'un traducteur de langue efficace.

Pour améliorer nos capacités, nous développerons un système de transpilation. Ce système utilisera des schémas de transpilation spécifiques pour convertir diverses entrées de données en formats utilisables. En utilisant notre matcher de grammaire pour valider la structure des entrées et le sélecteur pour la récupération des données, nous activerons des requêtes complexes contre notre base de données graphe ou générerons du bytecode pour interprétation.

## Plateforme Décentralisée pour l'Interaction avec les Données
En fin de compte, nous visons à créer une plateforme décentralisée qui tire parti des technologies développées tout au long de cette feuille de route. Cette plateforme facilitera la soumission, le filtrage, la classification et la modération des données. En créant une vaste base de données publique d'informations interconnectées, nous habiliterons les utilisateurs à interagir facilement avec les données via notre grand modèle linguistique, améliorant l'accessibilité et l'engagement au sein de notre communauté.

## Intégration des Clients
Nous utiliserons la même technologie que celle de notre plateforme de données décentralisée pour aider les entreprises à gérer efficacement leurs données. Avec notre système, elles pourront organiser leurs données avec des rôles et des permissions publics, secrets et privés. Une fois configurées, nous pourrons offrir des services d'hébergement de données cloud à ces clients en utilisant notre propre monnaie.

De plus, les entreprises auront la possibilité de connecter leurs bases de données à notre plateforme de données publiques, et elles pourront payer ces services avec notre monnaie décentralisée. Pour promouvoir la plateforme, les personnes qui référeront des clients à celle-ci gagneront une part des revenus en fonction des dépenses de leurs clients.

## Conclusion
La feuille de route de LegitDAO est un plan complet conçu pour construire un écosystème décentralisé qui favorise la collaboration, l'innovation et la transparence. Chaque phase de développement est étroitement liée, garantissant que nous créons une base solide pour l'avenir de l'intelligence artificielle générale (AGI). En tirant parti de l'implication de la communauté, des principes de l'open-source et de technologies de pointe, LegitDAO est prêt à transformer notre interaction avec l'IA et le monde numérique. Au fur et à mesure de notre progression, nous vous invitons à nous rejoindre dans cette passionnante aventure, en apportant vos idées et votre expertise pour concrétiser notre vision.