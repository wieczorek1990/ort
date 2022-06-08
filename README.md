ort
===

Simple program for Polish ortography learning.

## Installation:

### ort

Setup `bin/config.sh` with your favourite text editor and run `bash bin/install.sh`.

If you want to install the results server, run `bash bin/install.sh server`.

To uninstall run `bash bin/uninstall.sh`.

## Launching

Launch program in terminal by `ort`.

Launch server in terminal by `ort_server`.

## Keyboard settings

Up/down arrows - choosing.

Space, enter - confirmation.

CTRL+C, ESC - exit.

CTRL+\ - exit after cheating.

## Configuration

Setup `data/config.yml` to suit your needs.

Results databases are stored in `~/.ort-db` directory.

### Dictionary

You can edit the `data/pl_PL.dic` dictionary if you think that ~300k
words is too much or need a specific set of words.

To download newer version of dictionary run `bash bin/dictionary.sh`.

## Localization

If you want to localize **ort**, create a `$language.yml` file and send a
pull request.

---

ort
===

Prosty program do nauki polskiej ortografii.

## Instalacja

### ort

Ustaw `bin/config.sh` ulubionym edytorem tekstowym i uruchom `bash bin/install.sh`.

Jeżeli chcesz zainstalować serwer wyników uruchom `bash bin/install.sh server`.

By odinstalować uruchom `bash bin/uninstall.sh`.

## Uruchamianie

Uruchom program w terminalu przez `ort`.

Uruchom serwer w terminalu przez `ort_server`.

## Ustawienia klawiatury

Strzałki góra/dół - wybór.

Spacja, enter - zatwierdzanie.

CTRL+C, ESC - wyjście.

CTRL+\ - wyjście po oszukiwaniu.

## Konfiguracja

Ustaw `data/config.yml` tak by Ci odpowiadał.

Bazy danych wyników przechowywane są w katalogu `~/.ort-db`.

## Słownik

Możesz edytować słownik `data/pl_PL.dic`, jeżeli uważasz że ~300k słów to za dużo lub potrzebujesz specyficznego zbioru słów.

By ściągnąć nowszą wersję słownika uruchom `bash bin/dictionary.sh`.

## Lokalizacja

Jeżeli chcesz przetłumaczyć **ort**, utwórz plik `$język.yml` i wyślij pull request.
