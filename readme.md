<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

License
-------

This library written by Torben Sickert stands under a creative commons naming
4.0 international license.
See https://creativecommons.org/licenses/by/4.0/deed.de
endregion -->

<!--|deDE:Einsatzmöglichkeiten-->
<!--|frFR:Cas d'utilisation-->
Use case
--------

A composite GitHub action which prepares a new release of a repository. It
determines the next semantic version, writes it into "package.json" and
"PKGBUILD", commits the change and tags it. Publishing the result is left to
the following steps, e.g. those of
[build-package-push-action](https://github.com/thaibault/build-package-push-action),
which uses this action.
<!--deDE:
    Eine zusammengesetzte GitHub-Action, die eine neue Version eines
    Repositorys vorbereitet. Sie ermittelt die nächste semantische Version,
    schreibt sie in "package.json" und "PKGBUILD", committet die Änderung
    und taggt sie. Das Veröffentlichen bleibt den folgenden Schritten
    überlassen, z. B. denen von
    [build-package-push-action](https://github.com/thaibault/build-package-push-action),
    die diese Action verwendet.
-->
<!--frFR:
    Une action GitHub composite qui prépare une nouvelle version d'un dépôt.
    Elle détermine la prochaine version sémantique, l'écrit dans
    "package.json" et "PKGBUILD", committe la modification et la tague. La
    publication du résultat est laissée aux étapes suivantes, par exemple
    celles de
    [build-package-push-action](https://github.com/thaibault/build-package-push-action),
    qui utilise cette action.
-->

<div class="wd-table-of-contents">
    <h2 id="content">Content<!--deDE:Inhalt--><!--frFR:Contenu--></h2>
    <!--wd-table-of-contents-->
</div>

<!--|deDE:Verwendung-->
<!--|frFR:Utilisation-->
Usage
-----

The action checks out the repository itself. The following workflow tags a
new version when it is started manually from the "Actions" tab:
<!--deDE:
    Die Action checkt das Repository selbst aus. Der folgende Workflow taggt
    eine neue Version, wenn er manuell im Reiter "Actions" gestartet wird:
-->
<!--frFR:
    L'action récupère elle-même le dépôt. Le workflow suivant tague une
    nouvelle version lorsqu'il est lancé manuellement depuis l'onglet
    "Actions":
-->

```yaml
name: Prepare release

on:
  workflow_dispatch:
    inputs:
      type:
        description: Sets semantic version update type.
        default: patch
        type: choice
        options:
          - major
          - minor
          - patch
          - candidate

permissions:
  # Required to push the release commit and tag.
  contents: write

jobs:
  main:
    runs-on: ubuntu-latest
    container: node:lts

    steps:
      - uses: thaibault/prepare-release-action@main
        id: prepare-release
        with:
          type: ${{ inputs.type || 'patch' }}

      - name: Print determined version.
        run: echo Newly determined version is \"${{ steps.prepare-release.outputs.version }}\".
        shell: bash
```

A release runs through the following steps:
<!--deDE:Eine Veröffentlichung durchläuft die folgenden Schritte:-->
<!--frFR:Une publication passe par les étapes suivantes:-->

1. The repository is checked out including its tags.<!--deDE:Das Repository wird inklusive seiner Tags ausgecheckt.--><!--frFR:Le dépôt est récupéré avec ses tags.-->
2. With a "package.json" the dependencies are installed via [install-npm-package-dependencies-action](https://github.com/thaibault/install-npm-package-dependencies-action).<!--deDE:Mit einer "package.json" werden die Abhängigkeiten über [install-npm-package-dependencies-action](https://github.com/thaibault/install-npm-package-dependencies-action) installiert.--><!--frFR:Avec un "package.json", les dépendances sont installées via [install-npm-package-dependencies-action](https://github.com/thaibault/install-npm-package-dependencies-action).-->
3. The new version is determined and written into the manifest files, see [Versions](#versions).<!--deDE:Die neue Version wird ermittelt und in die Manifest-Dateien geschrieben, siehe [Versionen](#versions).--><!--frFR:La nouvelle version est déterminée et écrite dans les fichiers manifestes, voir [Versions](#versions).-->
4. "npm pkg fix" brings "package.json" into the form npm expects for publishing.<!--deDE:"npm pkg fix" bringt die "package.json" in die Form, die npm zum Veröffentlichen erwartet.--><!--frFR:"npm pkg fix" met le "package.json" dans la forme attendue par npm pour la publication.-->
5. All changes are committed as "Publish new version "v&lt;version&gt;"." and tagged as "v&lt;version&gt;". If there is nothing to commit, the current commit is tagged.<!--deDE:Alle Änderungen werden als "Publish new version "v&lt;version&gt;"." committet und als "v&lt;version&gt;" getaggt. Gibt es nichts zu committen, wird der aktuelle Commit getaggt.--><!--frFR:Toutes les modifications sont committées sous "Publish new version "v&lt;version&gt;"." et taguées "v&lt;version&gt;". S'il n'y a rien à committer, le commit actuel est tagué.-->

The job needs "contents: write" to push the commit and the tag. In a container
running as root, the action marks the workspace as safe for git itself.
<!--deDE:
    Der Job braucht "contents: write", um den Commit und das Tag zu pushen.
    In einem als root laufenden Container markiert die Action den
    Arbeitsbereich selbst als sicher für git.
-->
<!--frFR:
    Le job a besoin de "contents: write" pour pousser le commit et le tag.
    Dans un conteneur exécuté en root, l'action marque elle-même l'espace de
    travail comme sûr pour git.
-->

<!--|deDE:Eingaben-->
<!--|frFR:Entrées-->
Inputs
------

- "type": "major", "minor", "patch" (default) or "candidate", see [Versions](#versions).<!--deDE:"type": "major", "minor", "patch" (Standard) oder "candidate", siehe [Versionen](#versions).--><!--frFR:"type": "major", "minor", "patch" (par défaut) ou "candidate", voir [Versions](#versions).-->
- "debug": "true" sets "NODE_ENV" to "debug" while installing dependencies. Default "false".<!--deDE:"debug": "true" setzt "NODE_ENV" beim Installieren der Abhängigkeiten auf "debug". Standard "false".--><!--frFR:"debug": "true" met "NODE_ENV" à "debug" lors de l'installation des dépendances. Par défaut "false".-->

<!--|deDE:Ausgaben-->
<!--|frFR:Sorties-->
Outputs
-------

- "version": the new version including the "v" prefix, e.g. "v1.0.3" or "v1.0.3-1".<!--deDE:"version": die neue Version inklusive des Präfixes "v", z. B. "v1.0.3" oder "v1.0.3-1".--><!--frFR:"version": la nouvelle version, préfixe "v" inclus, par exemple "v1.0.3" ou "v1.0.3-1".-->
- "has-package-json": "true" if the repository contains a non-empty "package.json", otherwise "false".<!--deDE:"has-package-json": "true", wenn das Repository eine nicht leere "package.json" enthält, sonst "false".--><!--frFR:"has-package-json": "true" si le dépôt contient un "package.json" non vide, sinon "false".-->
- "has-pkgbuild": "true" if the repository contains a non-empty "PKGBUILD", otherwise "false".<!--deDE:"has-pkgbuild": "true", wenn das Repository ein nicht leeres "PKGBUILD" enthält, sonst "false".--><!--frFR:"has-pkgbuild": "true" si le dépôt contient un "PKGBUILD" non vide, sinon "false".-->

<!--|deDE:Versionen-->
<!--|frFR:Versions-->
Versions
--------

Versions have the form "&lt;major&gt;.&lt;minor&gt;.&lt;patch&gt;", release
candidates append "-&lt;number&gt;". The current version is read from the
first available source:
<!--deDE:
    Versionen haben die Form "&lt;major&gt;.&lt;minor&gt;.&lt;patch&gt;",
    Release-Kandidaten hängen "-&lt;number&gt;" an. Die aktuelle Version wird
    aus der ersten verfügbaren Quelle gelesen:
-->
<!--frFR:
    Les versions ont la forme "&lt;major&gt;.&lt;minor&gt;.&lt;patch&gt;", les
    versions candidates ajoutent "-&lt;number&gt;". La version actuelle est
    lue à partir de la première source disponible:
-->

1. the "version" of "package.json",<!--deDE:die "version" der "package.json",--><!--frFR:la "version" du "package.json",-->
2. the "pkgver" of "PKGBUILD",<!--deDE:das "pkgver" des "PKGBUILD",--><!--frFR:le "pkgver" du "PKGBUILD",-->
3. the highest tag of the form "v&lt;version&gt;", or "0.0.0" without any.<!--deDE:das höchste Tag der Form "v&lt;version&gt;" oder "0.0.0", wenn es keines gibt.--><!--frFR:le tag le plus élevé de la forme "v&lt;version&gt;", ou "0.0.0" s'il n'y en a aucun.-->

"major", "minor" and "patch" increment the respective part, reset the
following ones and drop a candidate number. "candidate" keeps the version and
increments its candidate number:
<!--deDE:
    "major", "minor" und "patch" erhöhen den jeweiligen Teil, setzen die
    folgenden zurück und entfernen eine Kandidatennummer. "candidate" behält
    die Version und erhöht ihre Kandidatennummer:
-->
<!--frFR:
    "major", "minor" et "patch" incrémentent la partie correspondante,
    remettent à zéro les suivantes et suppriment un numéro de candidat.
    "candidate" garde la version et incrémente son numéro de candidat:
-->

- "1.0.3" with "patch" becomes "1.0.4", with "minor" "1.1.0".<!--deDE:"1.0.3" wird mit "patch" zu "1.0.4", mit "minor" zu "1.1.0".--><!--frFR:"1.0.3" devient "1.0.4" avec "patch", "1.1.0" avec "minor".-->
- "1.0.3" with "candidate" becomes "1.0.3-1", "1.0.3-2" becomes "1.0.3-3".<!--deDE:"1.0.3" wird mit "candidate" zu "1.0.3-1", "1.0.3-2" zu "1.0.3-3".--><!--frFR:"1.0.3" devient "1.0.3-1" avec "candidate", "1.0.3-2" devient "1.0.3-3".-->
- "1.0.3-2" with "patch" becomes "1.0.4".<!--deDE:"1.0.3-2" wird mit "patch" zu "1.0.4".--><!--frFR:"1.0.3-2" devient "1.0.4" avec "patch".-->

The new version is written into "package.json". In "PKGBUILD", "pkgver" gets
the new version and "pkgrel" is reset to "1". Since "pkgver" can not contain
"-", a candidate leaves "PKGBUILD" untouched. Without "package.json" its
number is the next free one among the existing tags, so a "PKGBUILD" at
"1.0.3" with a tag "v1.0.3-1" gets "v1.0.3-2".
<!--deDE:
    Die neue Version wird in die "package.json" geschrieben. Im "PKGBUILD"
    erhält "pkgver" die neue Version und "pkgrel" wird auf "1"
    zurückgesetzt. Da "pkgver" kein "-" enthalten darf, lässt ein Kandidat
    das "PKGBUILD" unverändert. Ohne "package.json" ist seine Nummer die
    nächste freie unter den vorhandenen Tags, ein "PKGBUILD" auf "1.0.3" mit
    einem Tag "v1.0.3-1" erhält also "v1.0.3-2".
-->
<!--frFR:
    La nouvelle version est écrite dans le "package.json". Dans le
    "PKGBUILD", "pkgver" reçoit la nouvelle version et "pkgrel" est remis à
    "1". Comme "pkgver" ne peut pas contenir "-", une version candidate
    laisse le "PKGBUILD" inchangé. Sans "package.json", son numéro est le
    prochain libre parmi les tags existants, un "PKGBUILD" à "1.0.3" avec un
    tag "v1.0.3-1" obtient donc "v1.0.3-2".
-->

<!--|deDE:Lokal ausführen-->
<!--|frFR:Exécution locale-->
### Running locally

The version logic is a standalone Bash script. Run in the root of a
repository, it prints the next version without changing anything:
<!--deDE:
    Die Versionslogik ist ein eigenständiges Bash-Skript. Im Wurzelverzeichnis
    eines Repositorys ausgeführt, gibt es die nächste Version aus, ohne etwas
    zu ändern:
-->
<!--frFR:
    La logique de version est un script Bash autonome. Exécuté à la racine
    d'un dépôt, il affiche la prochaine version sans rien modifier:
-->

```bash
bash determine-version-and-update-manifest-files.sh minor
```

"--format" sets the output format, the action uses
'v${MAJOR}.${MINOR}.${PATCH}${CANDIDATE}'. "--update-manifest-file" also
writes the version into the manifest files, "--debug" prints the parsed parts.
The script needs GNU "sed" and, for a "package.json", "node".
<!--deDE:
    "--format" legt das Ausgabeformat fest, die Action verwendet
    'v${MAJOR}.${MINOR}.${PATCH}${CANDIDATE}'. "--update-manifest-file"
    schreibt die Version zusätzlich in die Manifest-Dateien, "--debug" gibt
    die erkannten Teile aus. Das Skript braucht GNU "sed" und, bei einer
    "package.json", "node".
-->
<!--frFR:
    "--format" définit le format de sortie, l'action utilise
    'v${MAJOR}.${MINOR}.${PATCH}${CANDIDATE}'. "--update-manifest-file"
    écrit aussi la version dans les fichiers manifestes, "--debug" affiche
    les parties reconnues. Le script nécessite le "sed" de GNU et, pour un
    "package.json", "node".
-->
