## Fabric Testviewer:

Testviewer is a dashboard that displays TPS trends for PTE, OTE, and LTE from daily CI run test results.

## Prerequisites:
You will need LTS versions of Node.js and npm installed. node@v8.11.2 and npm@6.1.0 were used for this project. There are no directory restrictions for the following commands. 

```
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
nvm install node@latest
npm install npm@6.1.0
```

Node modules also need to be installed for both the application and the server using the following commands.

In Testviewer directory,

```
cd ./app
npm install
cd ../server
npm install
```

## To run the application and the server

Again from the Testviewer directory, first start up the server then the application. 

```
node ./server/index.js
cd ./app
ng serve
```


## Ports

By default, the application will run on localhost:4200, and the server will run on localhost:3000.

### Application port
To change the application port, instead of running `ng serve`, run `ng serve --port PORT` where PORT is the desired port number.

### Server port
To change the server port, first open `Testviewer/server/index.js` and change the port constant to your desired port number.

Then, open `Testviewer/app/src/app/serveraction.ts` and change the port constant in that file as well.

