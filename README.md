# Sebas Adventure

**Sebas Adventure** est un jeu de plateforme 2D axé sur la vitesse et l'inertie, développé avec **Godot 4** et inspiré des jeux de plateforme classiques de l'ère 16 bits. Courez, dévalez les pentes, escaladez les murs, ramassez des anneaux et affrontez des ennemis.

> 🚧 **État du projet :** en développement. Certaines fonctionnalités, comme la boutique, les skins et le menu des options, ne sont pas encore disponibles.

---

## ✨ Fonctionnalités

- **Physique basée sur l'inertie :** la vitesse est conservée dans les pentes, les virages et les montées. Rouler en descente accélère le personnage, tandis que monter une pente le ralentit.
- **Compétences :**
  - `DOUBLEJUMP` : effectuer un deuxième saut en plein air.
  - `FAST` : augmenter de 50 % la vitesse maximale de course.
  - `SPINDASH` : charger une accélération en position accroupie, puis partir en roulant.
  - `CLIMB` : s'accrocher aux murs, les escalader et effectuer un saut mural.
  - `STOMP` : plonger vers le sol avec un effet de secousse de caméra.
- **Anneaux et vies :** les anneaux protègent contre un coup. Sans anneau, un coup fait perdre une vie. Chaque partie commence avec 3 vies.
- **Combats :** en roulant, en plongeant ou en sautant en boule, le personnage est invulnérable et peut détruire les ennemis.
- **Interface en jeu :** affichage du nom du joueur, des anneaux, du score et des vies.
- **Menus :** introduction vidéo, menu principal, saisie du nom du joueur, jeu, pause et écran de fin de partie.

---

## 🎮 Commandes

| Action | Touche |
|---|---|
| Se déplacer | `←` / `→` |
| Sauter | `Espace` |
| S'accroupir / rouler | `↓` |
| Charger un Spin Dash / effectuer un Stomp | `E` |
| Escalader (haut / bas) | `↑` / `↓` lorsqu'on est accroché à un mur |
| Mettre en pause | `Échap` |

### Techniques

- **Spin Dash :** maintenez `↓`, appuyez plusieurs fois sur `E` pour charger l'élan (pendant 3 secondes maximum), puis relâchez `↓`.
- **Saut en boule :** sautez en conservant la forme de boule, sans appuyer sur `E`, pour être invulnérable en l'air et conserver l'inertie à l'atterrissage.
- **Stomp :** en plein air, appuyez sur `E` pour plonger vers le sol.
- **Escalade :** en l'air, dirigez-vous vers un mur pour vous y accrocher. Sautez pour effectuer un saut mural.
- **Rebond :** détruire un ennemi en étant invulnérable donne une impulsion supplémentaire. Maintenez `Espace` pour rebondir plus haut.

---

## 🙏 Crédits

Une partie des ressources utilisées provient du pack de plateformes de **Brackeys**, publié sous licence CC0.

- **Sprites :** [RottingPixels](https://rottingpixels.itch.io/four-seasons-platformer-tileset-16x16free) (tileset et fruits).
- **Police :** [Pixel Operator](https://www.dafont.com/pixel-operator.font), créée par Jayvee Enaguas (HarvettFox96).
- **Moteur du jeu :** [Godot Engine](https://godotengine.org/).

Les ressources externes restent soumises à leurs licences respectives. Les éléments créés spécifiquement pour Sebas adventure, notamment les sprites, la musique, l'histoire et les niveaux, appartiennent à leur auteur.

---

## ▶️ Exécution du projet

### Prérequis

- [Godot 4.7](https://godotengine.org/download), version utilisée pour configurer le projet.

### Étapes

1. Clonez le dépôt et ouvrez le dossier du projet :
   ```bash
   git clone <url-du-depot>
   cd sadventure
   ```
2. Lancez Godot, cliquez sur **Importer** et sélectionnez le fichier `project.godot`.
3. Appuyez sur **F5** pour lancer le jeu.

> La fenêtre est configurée en 1440 × 900, sans bordure. Pour modifier ces paramètres, ouvrez **Projet → Paramètres du projet → Affichage → Fenêtre**.

---

## 📄 Licence

Les éléments originaux de Sebas adventure (code, sprites, musique, histoire et niveaux) sont destinés à rester la propriété de leur auteur. Les ressources tierces, comme celles du pack Brackeys, conservent leurs licences propres.

Aucune licence de réutilisation globale n'est définie pour le moment. Si vous souhaitez réserver les droits sur le projet, ne choisissez pas une licence open source telle que MIT ou CC0 : ajoutez plutôt un fichier `LICENSE` précisant les conditions d'utilisation. Gardez à l'esprit que les droits sur les ressources tierces ne peuvent pas être revendiqués comme si elles étaient toutes votre création.
