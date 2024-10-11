package main

import (
	"context"
	"log"
	"os"

	awsConfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var awsClient *s3.Client

const defaultPort = "7454"

func init() {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)

	cfg, err := awsConfig.LoadDefaultConfig(context.TODO(),
		awsConfig.WithRegion(os.Getenv("AWS_REGION")),
	)
	if err != nil {
		log.Fatalf("Error initializing AWS config: %v", err)
	}

	awsClient = s3.NewFromConfig(cfg)
}

func main() {
	for i := 0; i < MaxSimultaneousJobs; i++ {
		go jobWorker()
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = defaultPort
	}
	startWebServer(port)
}
