ort
===
Simple program for Polish ortography learning.
## Installation:
### Dependencies:
On Linux and Windows: `gem install colorize`

Additionally on Windows: `gem install highline`
### ort
Setup `config.sh` with your favourite text editor and run `bash install.sh`.

If you want to install the results server, run `bash install.sh server`.

To uninstall run `bash uninstall.sh`.
## Launching
Launch program in terminal by `ortografia`.

Launch server in terminal by `ortografia_server`.
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

To download newer version of dictionary run `bash update_dic.sh`.
## Localization
If you want to localize **ort**, create a `$language.yml` file and send a
pull request.

## Portability
**ort** should work with Ruby 1.9.3+ under Linux or Windows.

---
ort
===
Prosty program do nauki polskiej ortografii.
## Instalacja
### Zależności
Na Linux i Windows: `gem install colorize`

Dodatkowo na Windows: `gem install highline`
### ort
Ustaw `config.sh` ulubionym edytorem tekstowym i uruchom `bash install.sh`.

Jeżeli chcesz zainstalować serwer wyników uruchom `bash install.sh server`.

By odinstalować uruchom `bash uninstall.sh`.
## Uruchamianie
Uruchom program w terminalu przez `ortografia`.

Uruchom serwer w terminalu przez `ortografia_server`.
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

By ściągnąć nowszą wersję słownika uruchom `bash update_dic.sh`.
## Lokalizacja
Jeżeli chcesz przetłumaczyć **ort**, utwórz plik `$język.yml` i wyślij pull request.

## Przenośność
**ort** powienien działać z Ruby 1.9.3+ pod Linux i Windows.
