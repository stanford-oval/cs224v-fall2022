# Build a QA skill for a Wikidata domain with Genie

This part of the homework brings up the system by running a few automated scripts.

## Table of contents

- [Setup](#setup)
    - [Google Cloud Platform](#google-cloud-platform)
    - [Install libraries and dependencies](#install-libraries-and-dependencies)
- [Data synthesis](#data-synthesis)
- [Train a semantic parser](#train-a-semantic-parser)
- [Evaluate the semantic parser](#evaluate-the-semantic-parser)
- [Talk to your model](#talk-to-your-model)
- [Submission](#submission)

## Setup

### Google Cloud Platform

This homework requires access to significant computing resources. We recommend running **all steps** in Google Cloud Platform. All students have received a Google Cloud Platform coupon for this class. [Here](https://gcp.secure.force.com/GCPEDU?cid=Uyi9ze1O1S9sSxN1TfeSwKoLrjxc13s%2FZJmVEQdY7EqdCDahnnfFYTorB21fOL6L/) is the URL you will need to access in order to request a Google Cloud coupon. You will be asked to provide your school email address and name. An email will be sent to you to confirm these details before a coupon is sent to you.

Once you have redeemed your coupon, **follow this [instruction](./google-cloud.md) to setup your VM.**

You will be responsible for creating and managing (starting, stopping) the VM instances used by this homework. You will be billed while the instances are running (and you will be responsible for charges beyond the coupon), so make sure you **turn off any VM instance you are not using**.

### Install libraries and dependencies
To install the libraries and dependencies needed, clone this repository and run the following command (takes about 3 minutes)

**Again, we strongly recommend doing this on your VM via the gcloud command!**

```bash
git clone https://github.com/stanford-oval/cs224v-fall2022.git
cd cs224v-fall2022/hw2
./install.sh
```

Since both the synthesis and training take a long time to finish, we **highly recommend** running everything using a terminal multiplexer such as [screen](https://www.gnu.org/software/screen/) and [tmux](https://github.com/tmux/tmux/wiki) to avoid potential lost of progress due to disconnction. A cheatsheet on these topics can be found [here](./multiplexers.md). 

## Prepare training data for a domain of your choice. 

The input to the semantic parser is a natural language utterance, and the output is a formal representation of the sentence in the ThingTalk language.  Thus, the training data set consists of pairs of natural language utterance and its corresponding Thingtalk representation.  
The [CSQA dataset](https://amritasaha1812.github.io/CSQA/) is a released dataset of questions and answers on Wikidata. We use this dataset in two ways:
(1) Add a small number of questions from the CSQA dataset (and their ThingTalk representation) as training data.  This complements the synthesized dataset.  We refer to this small data addition as "few-shot" training data.
(2) We do not use synthesized data for validation (or known as dev) and test (also known as eval). We also create a dev set and an eval set from the CSQA dataset. 

### Pick a domain

Sign up for a domain [here](https://docs.google.com/spreadsheets/d/1lZ_3EGYKPKvCtNV9kYschN7cnlKt03az9k3zSASa9tw/edit?usp=sharing) (using your Stanford email account). Each domain only has 5 slots maximum, so act quickly to secure the one you want to try. 

Edit the Makefile to set `experiment` to the domain you signed up at line 8 as follows:
```make
experiment ?= <YOUR_DOMAIN>
```
Make sure the domain name is in **lower-case**. 

### Get the domain data and generate training data

The following command automatically copies over the data for the domain and synthesizes the data:
```bash
source .virtualenv/genie/bin/activate
make datadir 
```
The step will take about 1 hour, depending on the domain. 

It will create:
- the manifest, `<DOMAIN>/manifest.tt`. This contains the schema of the domain, including entities involved, all properties, and their natural language annotations. *(Side note: If you are using VS Code, we have developed a simple [syntax highlighter](https://marketplace.visualstudio.com/items?itemName=ShichengLiu.thingtalk-syntax-highlighter) for `.tt` files. You can install it directly from Marketplace. If you have suggestions about what additional functionalities you'd find useful, feel free to create feature requests on its GitHub page.)*; 
- a parameter dataset for augmentation, in `<DOMAIN>/parameter-dataset`. This contains information that will augment the automatically synthesized data with more entity data (e.g. names of people, countries, etc.)
- a dataset in `datadir`. This training data set (`datadir/train.tsv`) is composed of (1) synthetic data generated based on the manifest (2) 100 examples converted from CSQA training set, both augmented with the parameter datasets. In addition, there is a validation set (`datadir/valid.tsv`) and a test set, converted from CSQA dev set. 

Please take a look at the data prepared for you. The Genie system uses the first two files (manifest and parameter dataset) for data synthesis.

The `manifest.tt` file contains the set of properties in your domain. Search for `list query` to locate the domain signature, and all properties are listed inside the parentheses in the format `out <NAME> : <TYPE>`. Each of them is also annotated with `#_[canonical={}]` which includes how the property can be described in natural language in different parts of speech. For more details about the annotation syntax, check out the [Genie Annotation Reference](https://wiki.almond.stanford.edu/en/references/genie-annotation) guide.

Check out the training set (`datadir/train.tsv`) and dev set (`datadir/valid.tsv`) to see how the synthesized training queries and evaluation queries look like. You should not look at the test set, because you are not allowed to tune the training data or the model based on knowledge in the test set. 

Each line in the data files is a training sample, consisting of the ID of the sample, the lowercased natural language utterance, and the gold Thingtalk program.

**If you want to re-run this step, make sure to run `make clean` first. Otherwise, `make` will not regenerate files that already exist.**

## Train a semantic parser 
We can now start training using the following command
```bash
make train
```
This takes about 1 hour with V100/P100 GPU or 4 hours with K80.
You can start a tensorboard with `tensorboard --logdir <DOMAIN>/models` (replace `<DOMAIN>` with your domain name) to monitor the training. 
Once tensorboard is running in the VM. Run the following command on your PC to port forward tensorboard:
```bash
gcloud compute ssh --zone "<YOUR_ZONE>" "<YOUR_VM_NAME>" -- -NfL 6006:localhost:6006
```
Now you can open tensorboard in your browser: http://localhost:6006/.

## Evaluate the semantic parser
To check the accuracy of the trained model over the evaluation set of CSQA, run 
```bash
make evaluate
```
After the evaluation finishes, you will have two files:
- `./<DOMAIN>/eval/1.results`: short file in CSV form containing accuracy
- `./<DOMAIN>/eval/1.debug`: the error analysis file which compares the output of the model with the gold annotation, and reports all the errors

See [instructions/eval-metrics.md](./eval-metrics.md) for details of these files.

Note: To reduce cost and time, we generate a relatively small dataset (10K~20K examples) in this homework and train for only 10K iterations. In practice, we can synthesize a much larger dataset and train for more iterations, which will give us a few percent of improvement on accuracy.

Note: Despite decent accuracy reported on artificial validation set, the agent is very likely to perform poorly in real world. We will be exploring more on this in part 2.

## Submission
Each student should submit a pdf file and include the following: 
- The domain you chose
- The accuracy of your model (from `./<DOMAIN>/eval/1.results`) and a screenshot of the tenserboard `almond/em/val` plot
