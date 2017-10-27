#!/bin/bash
mvn package
cp target/peer-javasdk-1.0-jar-with-dependencies-exclude-resources.jar peer-javasdk.jar
