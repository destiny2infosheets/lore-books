# DIM's API key. insanity_wolf.jpg: it's public anyways.
API_KEY := 5ec01caf6aee450d9dabe646294ffdc9

.PHONY: all
all: tmp/books.marker
	# Start a new instance of make, so that generated JSON files are visible as
	# target dependencies.
	$(MAKE) epubs

.PHONY: update
update:
	rm tmp/manifest.json || true
	$(MAKE)

tmp out:
	mkdir $@

################################################################################
# Stage 1: fetch the manifest and extract lore books as separate files.
################################################################################

tmp/manifest.json: | tmp
	path="$$(curl --silent --header 'X-API-Key: $(API_KEY)' https://www.bungie.net/Platform/Destiny2/Manifest/ \
	  | jq --raw-output .Response.jsonWorldContentPaths.en)"; \
	url="https://www.bungie.net$${path}"; \
	curl --silent --header 'X-API-Key: $(API_KEY)' --header 'Content-Type: application/json' "$${url}" | jq > $@

books.json: tmp/manifest.json extract_books.jq
	jq -f extract_books.jq tmp/manifest.json > $@

tmp/books.marker: books.json
	jq '.[] | .hash' --raw-output $< | while read hash; do \
		temp="tmp/book_$${hash}.json"; \
		jq ".[] | select(.hash == $${hash})" $< > "$${temp}"; \
		target="tmp/$$(jq --raw-output '.makeSafeTitle' "$${temp}").book.json"; \
		if [ -r "$${target}" ] && cmp -s "$${temp}" "$${target}"; then \
			rm "$${temp}"; \
		else \
			mv -f "$${temp}" "$${target}"; \
		fi \
	done
	touch $@

.PHONY: books
books: tmp/books.marker

################################################################################
# Stage 2: convert each book into epub. Highly parallelizable.
################################################################################

%.png: %.book.json
	curl --silent https://www.bungie.net$$(jq --raw-output '.cover' '$<') > '$@'

%.txt: %.book.json format_book.jq
	jq --raw-output -f format_book.jq '$<' > '$@'

%.md: %.txt
	awk 'BEGIN {i=0} i == 2 {print} /^---$$/ {i++}' $< > $@

out/%.epub: tmp/%.txt tmp/%.png | out
	cd tmp && pandoc '$(patsubst tmp/%,%,$<)' -o '../$@'

.PHONY: images texts epubs
images: $(patsubst %.book.json,%.png,$(wildcard tmp/*.book.json))
texts: $(patsubst %.book.json,%.txt,$(wildcard tmp/*.book.json))
texts: $(patsubst %.book.json,%.md,$(wildcard tmp/*.book.json))
epubs: images $(patsubst tmp/%.book.json,out/%.epub,$(wildcard tmp/*.book.json))

books.zip: epubs
	cd out && zip ../$@ *.epub

clean:
	rm -r tmp out || true
