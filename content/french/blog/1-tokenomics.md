---
title: "Tokenomique de l’écosystème LegitDAO"
meta_title: "Tokenomique de l’écosystème LegitDAO"
description: "Cet article de blog explique la tokenomique de l’écosystème LegitDAO."
date: 2024-10-19T05:00:00Z
image: "/images/blogs/tokenonomics.png"
categories: ["Tokenomique"]
author: "Steve Rodrigue"
tags: ["tokenomique", "smart-contracts"]
draft: false
---
Dans l'écosystème de LegitDAO, les fondateurs sont les individus qui ont initialement conçu le projet et fourni les ressources nécessaires pour le lancer. Ils ont été responsables de la planification du développement initial de la technologie, de l'établissement de la tokenomique, et de la promotion du projet pour former la communauté initiale de soutiens à LegitDAO.

## Fondateurs
Les fondateurs de LegitDAO sont la force motrice derrière l'organisation, responsables de la mise en œuvre du projet. Ces personnes n'ont pas seulement lancé le concept, mais ont également fourni les ressources nécessaires pour réussir le lancement de la DAO. Leurs rôles comprenaient la planification du développement initial de la technologie, l'établissement de la tokenomique, et la promotion de l'entreprise afin de créer la première communauté de soutiens de LegitDAO.

Dans le cadre de LegitDAO, il y a six membres fondateurs, chacun détenant une part importante dans l'organisation. Ils détiendront chacun 16 666 666 tokens, contribuant à un total de 99 999 996 tokens pour le contrat intelligent. Cette structure permet une distribution contrôlée des tokens et crée un marché où les fondateurs peuvent vendre leurs tokens à la communauté en échange de BNB coins. Un aspect intéressant de ce marché est qu'il n'y a pas de taxe sur les échanges des unités des fondateurs, ce qui en fait une option attrayante pour les investisseurs initiaux.

## Programme d'affiliation
Le programme d'affiliation au sein de LegitDAO est conçu pour encourager la croissance de la communauté en récompensant les individus qui réfèrent de nouveaux membres à la plateforme. Ce contrat intelligent permet aux utilisateurs d'enregistrer leurs portefeuilles et de construire un arbre d'affiliation à plusieurs niveaux, améliorant ainsi la portée globale de la DAO.

Au départ, les recommandations provenaient d'amis et de la famille durant la phase de planification, menant à la formation d'une communauté d'environ 300 membres. Chaque fois qu'une personne est référée, elle devient également membre du réseau d'affiliation de la personne qui l'a référée, permettant la création d'une structure à plusieurs niveaux. Le programme d'affiliation comprend un marché où les utilisateurs peuvent acheter et vendre leurs arbres d'affiliation en échange de BNB coins. Il est important de noter qu'il n'y a pas de frais pour échanger des arbres d'affiliation, favorisant un environnement collaboratif et engageant.

## Contrat intelligent DAO
Le contrat intelligent DAO est un contrat conforme ERC-20 avec des capacités supplémentaires adaptées à LegitDAO. Il détient des tokens assignés aux membres de la communauté, en particulier les amis et la famille des fondateurs. Lorsque des individus contribuent à la DAO, ils sont récompensés par des tokens proportionnels à leur contribution.

Par exemple, si un membre contribue 2 000 $, il recevra un montant calculé de tokens DAO basé sur le total des contributions. Il est important de noter que 15 % de chaque contribution est attribué à l'arbre d'affiliation qui a amené ces personnes dans la DAO. Durant la phase de planification, LegitDAO a accumulé un total de 1,6 million de dollars canadiens en contributions, qui ont été conservés en toute sécurité en Bitcoin jusqu'au lancement du projet. Une fois le contrat intelligent DAO déployé, ces fonds seront convertis en BNB coins et gérés par la communauté.

### Exemple concret
Pour illustrer le fonctionnement du système de contribution, considérons le scénario suivant. La DAO a accumulé 1,6 million de dollars canadiens, et l'offre totale de tokens est de 115 millions.

- Jack contribue 2 000 $ et réfère Anna, qui contribue 1 $, puis Anna réfère Johnny, qui contribue 1 000 $ au projet.
- Jack recevra 125 000 tokens pour sa contribution.
- Anna recevra 62 tokens pour sa contribution.
- Johnny recevra 62 500 tokens pour sa contribution.
- De plus, Anna gagnera 9 375 tokens pour avoir référé Johnny.
- Jack gagnera également des tokens pour avoir référé Anna et Johnny.

Au total, la distribution des tokens serait la suivante :
- Jack aura 126 415 tokens.
- Anna aura 9 437 tokens.
- Johnny recevra 62 000 tokens.

### Minting de tokens
Le contrat DAO est conçu pour frapper 100 % de ses tokens lors du déploiement. Aucun token supplémentaire ne sera créé à l'avenir, garantissant que l'offre totale reste fixe.

### Marché dans le contrat intelligent DAO
Le contrat intelligent DAO comprend une fonctionnalité de marché qui permet aux utilisateurs d'acheter et de vendre des tokens en utilisant des BNB coins. Cela crée un environnement de trading actif, facilitant la liquidité au sein de l'écosystème DAO.

### Taxe de transfert
Lors du transfert de tokens DAO, que ce soit par le biais de ventes sur le marché ou de transferts directs entre portefeuilles, une taxe est appliquée. Il y a une taxe de 20 % lors de l'initiation d'un transfert et une taxe de 15 % lors de la réception des tokens. Ces frais sont répartis entre les personnes qui ont référé l'acheteur et le vendeur. Si un transfert a lieu sans référence, les frais iront au contrat des membres fondateurs.

## Contrat intelligent des prestataires de services
Le contrat intelligent des prestataires de services est développé spécifiquement pour ceux qui souhaitent proposer des services à la DAO. Chaque prestataire de services doit déployer son propre contrat et le connecter au contrat des propositions pour être éligible à l'exécution de contrats avec la DAO.

Ce contrat conforme ERC-20 permet une gestion ouverte des développeurs et des tâches, favorisant la transparence. La DAO peut suivre les tâches exécutées par chaque développeur, assurant ainsi responsabilité et clarté dans le projet.

### Taxe de transfert
Le contrat des prestataires de services inclut une taxe de transfert de 0,25 % pour l'expéditeur et 0,25 % pour le destinataire des tokens. Ces frais sont dirigés vers l'arbre d'affiliation qui a référé le prestataire de services. Si aucun référent n'existe, les frais vont au contrat des membres fondateurs.

## Contrat intelligent des développeurs
Le contrat intelligent des développeurs représente le premier prestataire de services dans l'écosystème LegitDAO. Ce développeur a réalisé toute la recherche et le développement initiaux du projet, créant du code essentiel qui sera intégré dans l'écosystème. Il utilise le code du contrat intelligent des prestataires de services.

## Monnaie
La monnaie utilisée au sein de LegitDAO est un contrat intelligent ERC-20 qui contient une offre totale de 100 millions de tokens. Au lancement, 200 000 tokens seront alloués au contrat intelligent des développeurs, tandis que les tokens restants seront disponibles à la vente en échange de BNB coins. Le prix initial commencera à 0,00001 BNB.

Chaque fois qu'un token est vendu, le prix du token suivant doublera, créant ainsi une structure de tarification dynamique.

Le contrat intelligent de la monnaie distribuera 80 % des BNB accumulés au contrat intelligent des développeurs, tandis que 5 % seront alloués à la DAO et 15 % serviront de paiements de référence. Si l'acheteur a été référé par quelqu'un, le paiement de référence ira à cet arbre de référence. Sinon, il sera envoyé au contrat des fondateurs.

### Taxe de transfert
Chaque fois qu'un transfert a lieu, une taxe de transfert de 0,25 % sera payée par l'expéditeur des tokens, et 0,25 % de la transfert sera payée par le destinataire. Ces frais seront dirigés vers le contrat intelligent des développeurs.

### Marché
Le contrat intelligent de la monnaie comprend également une fonctionnalité de marché, permettant aux utilisateurs d'acheter et de vendre des tokens pour des BNB coins.

## Proposition
Le contrat de proposition ne contient pas de monnaie ; il permet plutôt aux prestataires de services de s'enregistrer en tant que rédacteurs potentiels de propositions. La DAO examinera et approuvera ou rejettera les prestataires de services en fonction de la qualité de leurs informations publiques.

Une fois acceptés, les prestataires de services peuvent soumettre des propositions à ce contrat. La DAO votera ensuite pour accepter ou rejeter ces propositions en fonction de leur pertinence par rapport à la mission de l'organisation de développer les outils nécessaires à l'intelligence artificielle générale (AGI).

Lorsqu'une proposition est acceptée, les prestataires de services peuvent postuler pour exécuter le projet en fournissant un prix en monnaie de la DAO et en fixant un délai pour l'achèvement.

La DAO votera pour accepter le prestataire de services pour exécuter la proposition. À ce stade, la monnaie sera bloquée dans le contrat intelligent de la DAO.

Une fois qu'une proposition est terminée par le prestataire de services, la DAO vérifiera la qualité du travail. Si la proposition réussit, le prestataire de services sera automatiquement payé par le contrat intelligent de la DAO, et la proposition sera marquée comme réussie. Sinon, la proposition sera signalée comme infructueuse, et la monnaie bloquée sera libérée dans le contrat de la DAO.