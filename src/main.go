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

	// Build config options
	configOptions := []func(*awsConfig.LoadOptions) error{}

	// Add region if specified (optional for R2)
	if region := os.Getenv("AWS_REGION"); region != "" {
		configOptions = append(configOptions, awsConfig.WithRegion(region))
	} else {
		// Default to us-east-1 for AWS S3 compatibility, R2 ignores this
		configOptions = append(configOptions, awsConfig.WithRegion("us-east-1"))
	}

	cfg, err := awsConfig.LoadDefaultConfig(context.TODO(), configOptions...)
	if err != nil {
		log.Fatalf("Error initializing AWS config: %v", err)
	}

	// Create S3 client with custom endpoint if specified (for R2 or other S3-compatible services)
	s3Options := []func(*s3.Options){}
	if endpoint := os.Getenv("S3_ENDPOINT"); endpoint != "" {
		s3Options = append(s3Options, func(o *s3.Options) {
			o.BaseEndpoint = &endpoint
			// For R2 and other S3-compatible services, use path-style addressing
			o.UsePathStyle = true
		})
	}

	awsClient = s3.NewFromConfig(cfg, s3Options...)
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
