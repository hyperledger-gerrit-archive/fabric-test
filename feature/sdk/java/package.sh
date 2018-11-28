#!/bin/bash
mvn package
cp target/peer-javasdk-test-jar-with-dependencies-exclude-resources.jar peer-javasdk.jar
