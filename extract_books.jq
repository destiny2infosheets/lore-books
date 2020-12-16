def is_book($root): ((.children.records | length) > 0) and (until(. == null or .hash == 1993337477;  # 1993337477 is Triumphs > Lore presentation node
	if .parentNodeHashes | length > 0 then
		$root.DestinyPresentationNodeDefinition[.parentNodeHashes[0] | tostring]
	else null end) 
	| . != null);

def list_book_hashes: . as $root | .DestinyPresentationNodeDefinition[]
	| select(is_book($root)) | .hash | tostring;

def make_book(hash): . as $root | .DestinyPresentationNodeDefinition[hash | tostring]
| {
	hash: .hash,
	title: .displayProperties.name,
	cover: (.displayProperties.iconSequences | last | .frames | first),
	chapters: [
		.children.records[]
		| $root.DestinyRecordDefinition[.recordHash | tostring]
		| select(has("loreHash"))
		| $root.DestinyLoreDefinition[.loreHash | tostring]
		| {
			title: .displayProperties.name,
			text: .displayProperties.description,
		  }
	]
};

if $ARGS.named | has("book") then
	make_book($ARGS.named.book)
else
	list_book_hashes
end
