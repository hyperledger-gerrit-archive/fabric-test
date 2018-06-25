## Fabric Testviewer:

Testviewer is a dashboard that displays TPS trends for PTE, OTE, and LTE from daily CI run test results.

### Changing available tests to choose from

`Testviewer/app/src/app/testlists.ts` contains lists of tests that are available on Testviewer for PTE, OTE, and LTE tools. Adding/removing FAB numbers from these lists will change the lists of tests in the dropdown menus at the top of each tool metric section. 

'available' refers to tests that are available for each tool
'selected' refers to tests that are pre-selected for each tool



## Running Testviewer Locally

### Prerequisites:
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

### To run the application and the server

Again from the Testviewer directory, first start up the server then the application.

```
node ./server/index.js
cd ./app
ng serve
```


### Ports

Set `LOCAL = true` in `Testviewer/config.ts`

By default, the application will run on localhost:4200, and the server will run on localhost:3000.

#### Application port
To change the application port, instead of running `ng serve`, run `ng serve --port PORT` where PORT is the desired port number.

#### Server port
To change the server port, first open `Testviewer/server/index.js` and change the port constant to your desired port number.

Then, open `Testviewer/config.ts` and change the port constant in that file as well.



## Running Testviewer On with Docker

### Prerequisites

Docker needs to be installed from https://docs.docker.com/

### To run the application and server

`Dockerfile` and `docker-compose.yaml` are included in the Testviewer directory.

Run `docker build -t testviewer .` from the Testviewer directory to build the image from the Dockerfile.
Then, run `docker-compose up` to start up the app and the server.

### Ports

If you are using Docker locally, make sure `LOCAL = true` in `Testviewer/config.ts`.

By default, the application will run on localhost:4200, and the server will run on localhost:3000.
Port numbers can be edited on `docker-compose.yaml`.


## Running Testviewer On a Kubernetes Cluster

Make sure your IBM Cloud CLI and Kubernetes CLI are set up. `k8fabricreport.yaml` is included in the Testviewer directory.

### Deployment

The app and server are hosted remotely when they are deployed with the IBM Container Service using Kubernetes. In this case, the external IP address for this cluster needs to be specified so that when a user's browser opens the application, the application knows what IP to use to reach the server.

To do this, set `LOCAL = False` in `Testviewer/config.ts` and change REMOTE_IP and REMOTE_PORT as necessary.

Run `kubectl create -f k8fabricreport.yaml` from the `Testviewer` directory.
