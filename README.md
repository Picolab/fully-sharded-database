# fully-sharded-database
An experiment using picos to fully shard a database

## Presentation at IIW 32
This application was the focus of a presentation entitled
"Credential-Based Login To A Pico-Based Application"
at the 32nd Internet Identity Workshop, held virtually in April 2021
([PDF proceedings](https://github.com/windley/IIW_homepage/raw/gh-pages/assets/proceedings/IIW_32_Book_of_Proceedings_Final%20A%201.pdf), pp. 139-149).
These [slides](https://bruceatbyu.com/s/HRDDSiiw32) accompanied the presentation.

## Impetus for the PicoStack blog
The realization that this is a web application implemented entirely with picos
inspired the [first post](https://picostack.blogspot.com/2022/04/picos-as-web-application-development.html),
"Picos as a web application development stack".

### Web application written in KRL
Other than a handful of static assets,
in the [homepage](https://github.com/Picolab/fully-sharded-database/tree/main/homepage)
and [images](https://github.com/Picolab/fully-sharded-database/tree/main/images)
folders, every page of the application is delivered to the browser
by evaluating queries against KRL rulesets
in the [krl](https://github.com/Picolab/fully-sharded-database/tree/main/krl) folder.

### Web server setup
The setup of the webserver,
including providing a certificate so that it uses TLS,
is described in the [operations](https://github.com/Picolab/fully-sharded-database/tree/main/operations) folder.

## The fully-sharded database
The database could be compared to a table holding information about
_participants_, with a list pico representing the entire collection
and a participant pico representing each participant.

Currently there is an index on last name, first name.
Part of the experiment will include additional indexes,
and understanding how they are represented using picos and KRL rulesets.

## Verifiable credentials
Login requires a verifiable credential held in a smartphone wallet
to answer a proof request (as outlined in the slide deck mentioned earlier).

Both the credential and the verification are handled by calling
a [Trinsic](https://trinsic.id) API.

