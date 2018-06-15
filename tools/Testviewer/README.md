## Fabric Testviewer:

Testviewer is a dashboard that displays TPS trends for PTE, OTE, and LTE from daily CI run test results.

## Prerequisites:
You will need LTS versions of Node.js and npm installed. node@v8.11.2 and npm@6.1.0 were used for this project.

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
```
npm start ./app
node ./server/index.js
```

By default, the application will run on localhost:4200, and the server will run on localhost:3000.
