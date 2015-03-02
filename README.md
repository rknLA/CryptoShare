CryptoShare
===========

An open-source example of how to read and write encrypted files to Dropbox.


Original Concept
-------

The original idea behind this project was to build an open source library to
support developers in encrypting the data that they store on Dropbox.

After going through the weeds of implementing a rough JSON data store, I'm
no longer convinced that a general "encrypted JSON data store" is actually
general enough to be useful for other applications.

So, I'm still publishing this as an open proof-of-concept, but I'm not yet
convinced of what a general-purpose Objective-C API for Dropbox file
encryption would look like.


Realized Concept
----------------

The actual realized concept herein is a bit different.  It requests to
connect to your Dropbox account, then prompts you to create a passphrase.

Once you've created a passphrase, you can add items to a list.  In order to
access these items later, you'll need to use that passphrase.

After adding a few items, have a look at the files created by the app in
your Dropbox folder.


Usage
-----

You should be able to get away with cloning the repo, setting your Dropbox
API keys in `AppDelegate.m`, and building.  If that doesn't work, you may
have to add the Dropbox framework manually.


Implementation Notes
--------------------

This isn't extremely polished, or fully fleshed out enough to be a
production-ready product.  As mentioned above, I originally thought that it
would make sense to develop a general-purpose tool, but now think that the
extra efforts to do so don't provide nearly enough return for it to make
sense to continue right now.

Instead, I'm going to continue to work on my project that will use
derivatives of this work to encrypt end-user data.  If it makes sense to
revisit this after that app is done (or done enough), then I'll do that.
