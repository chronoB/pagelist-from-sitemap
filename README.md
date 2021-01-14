# pagelist-from-sitemap
Get a list of all pages of a website from a sitemap. First bashproject so I can't guarantee that this is going to work for anyone else because it's probably just hacked together but if you have any issues just let me know.

---
## Dependencies
xmlstarlet

For Ubuntu:
```bash
sudo apt install xmlstarlet
```

---
## Functionality

Run
```bash
./getpagelist.sh
```
with the following options:
| option | description                                                         |
| ------ | :------------------------------------------------------------------ |
| o      | output directory where the sitemaps and urls will be stored         |
| f      | file containing the urls of the websites. can't be used with w flag |
| w      | add a website that should be crawled. can't be used with f flag     |
| t      | for testing purposes only.                                          |

---
### Examples

Get all pages of page https://example.com
```bash
./getpagelist.sh -w example.com
```
Get all pages of the websites in the file websites.txt (every page is in a new line)
```bash
./getpagelist.sh -f websites.txt
```
Get all pages of page https://example.com and save them to a specific folder (can be relative and absolute)
```bash
./getpagelist.sh -w example.com -o ../myfolder/
```
