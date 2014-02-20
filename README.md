#wikitools

A few tools I whipped up for making a wikimedia XML dump into something useful as a natural-language corpus. It uses XML::Twig to reduce memory usage, and can process the English Wikipedia (EW) 43 GB XML dump without breaking a sweat.


##Setup

Make a table like this: 

    CREATE TABLE `wikipedia` (
      `id` int(11) NOT NULL,
      `title` text,
      `body` mediumtext,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8
    
Make sure it's UTF-8, since that's how the XML is encoded. That way we don't have to deal with conversion. Edit the wiki_ingest.pl script and make sure it has the right info for your database. Also, browse the `$boring` list to see if you'd like to change which titles are discarded. 

##Prune XML (optional)

This is recommended if you think you might have to do the import more than once, or if you want to keep a copy around for later. The `wiki_prune.pl` script strips out all the tags except title, body, and id. It also discards all redirects, and any articles with titles matching the `$boring` list. For the EW dump, it reduces the 14 million articles down to <5 million.  This took over 5 hours on my machine, but makes future steps much faster.

##Ingest
Run the `wiki_ingest.pl` script. You can pipe the XML into it, or run the script with the XML file as the first argument. This took 7 hours to read EW.

##Build indexes
For the EW dump, searching titles without an index takes about 20 minutes on my machine. I recommend putting a FULLTEXT index on the `title` column. This took 10 hours to build, and now fulltext matches only take 3 minutes. You can also put a FULLTEXT index on the `body` column. This took 15 hours. 

    ALTER TABLE wikipedia ADD  FULLTEXT KEY `title_index` (`title`);
    ALTER TABLE wikipedia ADD  FULLTEXT KEY `title_index` (`title`);
