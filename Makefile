# DIM's API key. insanity_wolf.jpg: it's public anyways.
API_KEY := 5ec01caf6aee450d9dabe646294ffdc9

.PHONY: all
all: tmp/books.marker
	# Start a new instance of make, so that generated JSON files are visible as
	# target dependencies.
	$(MAKE) epubs

tmp out:
	mkdir $@

################################################################################
# Stage 1
################################################################################

tmp/manifest.json: | tmp
	path="$$(curl --silent --header 'X-API-Key: $(API_KEY)' https://www.bungie.net/Platform/Destiny2/Manifest/ \
	  | jq --raw-output .Response.jsonWorldContentPaths.en)"; \
	url="https://www.bungie.net$${path}"; \
	curl --silent --header 'X-API-Key: $(API_KEY)' --header 'Content-Type: application/json' "$${url}" | jq > $@

tmp/books.json: tmp/manifest.json extract_books.jq
	jq -f extract_books.jq tmp/manifest.json > $@

tmp/books.marker: tmp/books.json
	jq '.[] | .hash' --raw-output $< | while read hash; do \
		jq ".[] | select(.hash == $${hash})" $< > tmp/book_$${hash}.json; \
		mv tmp/book_$${hash}.json "tmp/$$(jq --raw-output '.makeSafeTitle' tmp/book_$${hash}.json).book.json"; \
	done
	touch $@

################################################################################
# Stage 1
################################################################################

%.png: %.book.json
	curl --silent https://www.bungie.net$$(jq --raw-output '.cover' '$<') > '$@'

%.txt: %.book.json format_book.jq
	jq --raw-output -f format_book.jq '$<' > '$@'

out/%.epub: tmp/%.txt tmp/%.png | out
	cd tmp && pandoc '$(patsubst tmp/%,%,$<)' -o '../$(patsubst tmp/%,%,$@)'

.PHONY: images texts epubs
images: $(patsubst %.book.json,%.png,$(wildcard tmp/*.book.json))
texts: $(patsubst %.book.json,%.txt,$(wildcard tmp/*.book.json))
epubs: images $(patsubst tmp/%.book.json,out/%.epub,$(wildcard tmp/*.book.json))

clean:
	rm -r tmp out || true
