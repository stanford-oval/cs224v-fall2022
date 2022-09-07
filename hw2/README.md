# CS 224V Fall 2021 Homework 2:
# A Question-Answering Skill with a Neural Semantic Parser

This homework is designed to give you hands-on experience in building a question-answering (QA) skill for a virtual assistant, in preparation for your project in the course. You will learn how to use the Google cloud; how to define a basic skill; how to train a neural network; and how semantic parsing works. No prior knowledge in machine learning is assumed.  

Wikidata (https://www.wikidata.org) is the largest open structured data collection worldwide, consisting of 99,165,056 data items today. Wouldn't it be wonderful if consumers can take advantage of this knowledge base by querying the data using natural language? Due to its size, it is infeasible to manually annotate an adequate training data for this enormous data set. Genie reduces the need of manual annotation by synthesizing the training data directly from the schema of the knowledge base, with only just a little manual help. You will learn more about the technology in the lectures.

Your task in this assignment is to develop a skill for answering questions about one of the many domains in Wikidata. 


Warning: Although Genie automates many of the steps, the steps of data synthesis and training are both computation-intensive, running each command once may take about 1-2 hours. You need to start early, or you won't be able to complete the homework in time.
 
There are two parts to this homework. 

## [Part 1](./instructions/part-1.md)
Set up the environment and create a basic QA skill for a Wikidata domain with Genie

## [Part 2](./instructions/part-2.md)
Improve your Wikidata skill by adding a few annotations and a few samples of training data
