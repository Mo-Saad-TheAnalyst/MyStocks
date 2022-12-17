# MyStockTracker


# Overview

 - An ec2 instance is configured to scrape some stocks in realtime in an
   async fashion.
 - The data is then send to kinesis Datastream using aws  sdk for
   python.
 - The records are transformed with a lambda function to insure data
   integrity and also delivers the data to a time series database.
 - A firehouse stream is configured to patch the data for a maximum of 1
   min and sends the raw untransformed data to an s3 bucket.
 - A transformer lambda is then triggered to transform the data from
   JSON to parquet and provide dynamic partitioning and once again
   insures the data integrity.
 - A notification lambda is triggered to check if the price of the stock
   has decreased or increased by 1% and sends a mail if the conditions
   are met.
 - With the usage of a glue crawler the data will be available for
   further analysis and visualizations using Athena and Quicksight.

# What makes this project unique

 - Following the best practices in terms of security.
 - Usage of IaaC and the ability to deploy this solution in any region
   in different accounts.
 - Following SOLID principles and best practices when comes to software
   development.
 - Comprehensive guide on why I used certain services instead of others
   e.g. usage of influxdb instead of timestream.

# _Realtime ETL pipeline_

## Extraction

After some research on free stock api services, I couldn't find a free api service that has suitable amount of requests/day so the logical reason was to scrape the data manually from Yahoo finance in realtime.
The webscraper is deployed into an ec2 instance that runs infinitely or until the process is killed manually.
The scraper uses aws sdk to deliver the data directly to kinesis Datastream.

## Transformation
A lambda is triggered upon putting records into kinesis which in return does the required transformations to insure data integrity.

## Load

The reasonable choice for the database was a timeseris database due to the nature of the data and influxDB was then chosen knowing the fact that its opensource database.
The data is loaded to influxdb with the same **Transformation lambda** as it acts as the transformer and the loader.

# Realtime visualizations

Grafana is being used as the tool for monitoring and visualizing the stocks data due to the many capabilities it provides and it also has alerting service in real-time.

# Batch processing

 - A firehouse stream acts as a buffer for kinesis Datastream while
   dynamically partitioning the data by the date and the stock name.
 - A lambda is being triggered each time an object is put to the raw
   bucket which in return converts the file type from JSON to parquet
   and insure the data integrity inside the file.
 - The output object is then put to a different s3 bucket that will hold
   all the transformed data.
 - A glue crawler is being triggered daily to provide analysis
   capabilities with Athena and QS.
# Alerts and Notifications:

## Real-Time alerts

Grafana as a ready solution for alerting when a certain kpi has exceeded a specific threshold and this solution is the one used to realtime alert.

## Near real-time

A Lambda function is being triggered after a put event in the transformed bucket that checks for alerting conditions in the buffered data.

# Security Practices

 - the access to any ec2 is with a vpn from a specific IP and has the
   correct certificates.
 - IaM roles follows the least privilege principle
 - the usage of ec2 profiles instead of saving the configuration inside
   the ec2

# IaaC

AWS SDK is used to create a deployable solution as code which provides the ability to deploy the same solution on another account any region.

# Next steps: 

 - Enriching the stocks data with sentiment analysis from Twitter
       hashtags and analysis whether the sentiment affects the price of
       the stock.
 - Deploy a backtrading bot and test it's efficiency and whether
       that solution can be deployed in the real world.
 - Enhancing the webscraper with multiple IP proxies to prevent the
       possibility of getting banned and making the solution reselient
       to failure
 - Design a disaster recovery plan to insure that the solution meets
       TTL and point in time recovery.

