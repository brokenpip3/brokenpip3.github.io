+++
title = 'Taskwarrior practical guide #1 - tags, projects and dependencies'
date = 2025-02-09T23:52:49+01:00
draft = false
toc = true
tags = ["taskwarrior", "cli", "productivity", "practical-guide"]
+++

Yes, I know, there are plenty of options in the universe for a todo app.

How many times have you heard someone say something like: <<You should try this new shiny encrypted local-first connected social AI-driven todo app that will boost your productivity!>>

![sounds familiar](/images/taskwarrior-practical-guide/todo-dream.png "best todo list ever")

<center><i>Sound familiar, right?</i></center>

At the end, chasing the best todo app is not the supremely sophisticated way of procrastination?

Joking aside, I believe that **Taskwarrior** is not like the other todo apps you are used to (or if that’s the case, it will just be yet another todo app in your software graveyard).

This post is the first in a series where I will give a practical introduction to `task`.

## Introduction

### Why use a todo cli


Different people have different reasons for using a todo app.
For me, it’s mostly for two specific reasons:
* I often have my mind full of thoughts, most of the time about things to do.
  Writing them down as soon as I can is the perfect way to free myself and do a sort
  of "brain dump" that leaves me with more energy to spend on other thoughts (most of the time: other things to do).
* I often work on several things at once, usually more than two.
  While I’m trying to change this habit, having an "ongoing" task list is perfect because
  it helps me recognize how many tasks I’m juggling and decide to stop working on some of them so I can focus on just a few.

So, why a cli?

Because it’s handy: it can be used via SSH, piped into other tools, summoned at any moment or spot on my screen,
and in the specific case of Taskwarrior, it’s super extensible (I will talk more about this in the next post of this guide).

![hackerman](/images/taskwarrior-practical-guide/hackerman2.png "great series btw")

<center><i>Using only terminal apps for everything feels like</i></center>

### Why Taskwarrior

Taskwarrior is a very old (since 2006) todo app, and it’s one of those pieces of software created by brilliant minds.
The more you learn about it, the more amazed you’ll be at how well it’s designed.
Taskwarrior has, at its core, a unique way of handling tasks and the great extensibility will allow you to adapt it perfectly to your needs.

I know that I'm not replying to "why specifically taskwarrior" but I think that the best way to answer this question is to show how it works.
It’s like a long mountain path, you only realize how incredible the journey was after you’ve crossed it.

### Why "Practical"?

Enough with the high-level talk, let’s get to why "practical" is in the title.
Like the previously mentioned todo apps, everyone has their own way of learning.
For me, ever since I was a child, the best way to learn was to *do* something while reading about it.
This helps set it in my mind and makes it a part of what I’m trying to understand.

That’s why, for most of my IT knowledge, my approach has always been: read something, do it,
read more, do more, repeat, make mistakes, go back to the documentation, and so on.
This practical approach has always worked for me so it’s much easier for me to share things using practical examples, best practices, steps.

If you’re like me and interested in taskwarrior, this guide might be just what you need.

## Installation

Guess what, you can install it with your package manager.
Since it’s been around for a long time, you’ll find it in any of them from `brew` to `apt` or any os, so there’s no need to list all the options here.
But you can find the installation in the official [website](https://taskwarrior.org/download/) or the [repology](https://repology.org/project/taskwarrior/versions) one.

### Version

As of now, when I’m writing this post, the latest version is `3.3.0`.

This is important because, after being stalled for 2–3 years (but still working great), the project is now actively developed again.
This event has brought a major release: the `3.x` that it's not packaged already in any distro/os. This new major brings with some changes
(`sqlite` and rust just to mention two), however for the rest of this post, it doesn’t matter if you can install version `2.x` or `3.x`,
everything I will describe works in both versions.

## Let's Get Started

I want to avoid using typical examples like "buy milk" or "call mom." Let’s make it more interesting.
For instance, let’s say we need to create a new saas that will be a [Pagerduty](https://www.pagerduty.com/) clone.
The first thing we need to do is create multiple tasks and understand how we can link them together.

## Adding a Task

First, let’s just run the `task` command:

```bash
$ task
No matches.
```

Ok now let's start by adding our first task

```shell
$ task add make a financial plan
Created task 1.

$ task

ID Age  Description           Urg
 1 2s   make a financial plan    0
```

Nothing shocking here—we just added a task like in many other todo apps.
However, notice that each task has an ID, an age, and an urgency level.

Now let’s add a few more action items that we need to do create our Pagerduty clone:

```bash
$ task

ID Age  Description           Urg
 1 5min make a financial plan    0
 2 1min decide a cool name       0
 3 1min buy the dns domain       0
 4 1min buy a public ip          0
 5 2s   definite an mvp          0
```

They look like a standard list of things to do. Let's make much more with them.

## Tags

Taskwarrior has different concepts that we can use to organize our tasks. A tag is one way to do this.

For instance, we can tag all tasks related to finance with the tag `finance`.

### Adding a tag to existing tasks

```bash
$ task 1 modify tags:finance
Modifying task 1 'make a financial plan'.
Modified 1 task.

$ task

ID Age  Tag     Description           Urg
 1 7min finance make a financial plan  0.8
 2 3min         decide a cool name       0
 3 3min         buy the dns domain       0
 4 3min         buy a public ip          0
 5 1min         definite an mvp          0

5 tasks
```

Here, we’re using a command we haven’t seen before: the `modify` command.
`modify` lets you change the properties of a task. In this case, we added the tag finance to task 1.

As you can see, it’s super easy and fast, you don’t need to retype the whole task, you can just modify the specific properties you want.

Let’s continue refining our tasks by adding another tag to the tasks related to the tech part of our project:

```bash
$ task 3 4 modify tags:tech
This command will alter 2 tasks.
Modifying task 3 'buy the dns domain'.
Modifying task 4 'buy a public ip'.
Modified 2 tasks.

$ task

ID Age   Tag     Description           Urg
 1 16min finance make a financial plan  0.8
 3 12min tech    buy the dns domain     0.8
 4 12min tech    buy a public ip        0.8
 2 12min         decide a cool name       0
 5 11min         definite an mvp          0
```
As you can see, we can modify multiple tasks at the same time, and we can do so in a single command for any taskwarrior operation.

In general, any command in taskwarrior can be expressed as:

```bash
task <task_id> <command> <options>
```

Alternatively, the command can come before the task id, both options work, but the taskwarrior authors recommend using the first form.

You may have noticed that the urgency level of the tasks has changed.
We’ll discuss this in a bit, but for now, let’s stay focused on organizing our tasks.

### Filtering task by tags

Now that we added our tags we want to check only those tasks that have some tags attached:

Show me only the `finance` tasks:

```bash
$ task +finance

ID Age   Tag     Description           Urg
 1 16min finance make a financial plan  0.8

1 task
```

Now show me everything except the tech ones:

```bash
$ task -tech

ID Age   Tag     Description           Urg
 1 16min finance make a financial plan  0.8
 2 12min         decide a cool name       0
 5 11min         definite an mvp          0
```

Show me the tasks that contains `finance` or the ones that contains `tech`

```bash
$ task +finance or +tech

ID Age   Tag     Description           Urg
 1 16min finance make a financial plan  0.8
 3 12min tech    buy the dns domain     0.8
 4 12min tech    buy a public ip        0.8
```

as you can see we can use the `+` and `-` to filter our tasks.
The nice part is that you can use your shell completion to do it so you need to remember each tags, especially after a while.

## Projects

The project concept is straightforward; it is a way to group tasks together that are related to a specific goal.

We can have the same or multiple tags for different projects, but each task can only belong to one project.

### Assign tasks to a project

Our tasks are all related to our saas project, so let's add the project `saas` to all of them.

```bash
$ task 1-5 modify project:saas #notice that I used a range here
This command will alter 5 tasks.
  - Project will be set to 'saas'.
Modify task 1 'make a financial plan'? (yes/no/all/quit) all
Modifying task 1 'make a financial plan'.
Modifying task 2 'decide a cool name'.
Modifying task 3 'buy the dns domain'.
Modifying task 4 'buy a public ip'.
Modifying task 5 'definite an mvp'.
Modified 5 tasks.
The project 'saas' has changed.  Project 'saas' is 0% complete (5 of 5 tasks remaining).

$ task

ID Age     Project Tag     Description           Urg
 1 16min   saas    finance make a financial plan  1.8
 3 12min   saas    tech    buy the dns domain     1.8
 4 12min   saas    tech    buy a public ip        1.8
 2 12min   saas            decide a cool name       1
 5 12min   saas            definite an mvp          1
```

Cool, now we have all our task grouped in the project `saas`.

### Subprojects

Okay, but you are a complex human being, right? You can't handle your multifaceted life with just one project.
You need to have subprojects. You need to break down your projects into smaller parts.
Let's say, for instance, that we want to create a subproject related to the tax aspects of our saas project.

In taskwarrior we can create a subproject by using the dot notation (`.`), so in our case, we can use for instance `saas.taxes`:

```bash
$ task add call the tax accountant to undestand the next steps project:saas.taxes
Created task 6.
The project 'saas.taxes' has changed.  Project 'saas.taxes' is 0% complete (1 task remaining).

$ task add produce the documentation we need to register the ltd project:saas.taxes
Created task 7.
The project 'saas.taxes' has changed.  Project 'saas.taxes' is 0% complete (2 of 2 tasks remaining).

$ task

ID Age   Project    Tag     Description                                           Urg
 1  1h   saas       finance make a financial plan                                  1.8
 3  1h   saas       tech    buy the dns domain                                     1.8
 4  1h   saas       tech    buy a public ip                                        1.8
 2  1h   saas               decide a cool name                                       1
 5  1h   saas               definite an mvp                                          1
 6 46s   saas.taxes         call the tax accountant to undestand the next steps      1
 7  2s   saas.taxes         produce the documentation we need to register the ltd    1

7 tasks
```

we just added the `taxes` subproject to our sass project, let's see how we can filter them.

### List projects

Like tags we can list task that are part of a project with the `project:` filter:

```bash

$ task project:saas.taxes

ID Age   Project    Description                                           Urg
 6 19min saas.taxes call the tax accountant to undestand the next steps      1
 7 19min saas.taxes produce the documentation we need to register the ltd    1

2 tasks
```

or count them (`count` is a special command that returns the number of tasks that match the filter):

```bash
$ task project:saas.taxes count
2
```

If we want to see a more general view of our projects we can use the `projects` (with `s`) command:

```bash
$ task projects

Project Tasks
saas        7
  taxes     2
```

## Start, done, summary

So we add our initial task for the pagerduty clone project, we tagged them and we grouped them in a project.

Now let' so the most difficult part when you use a todo app, let's start to work on them.

```bash
$ task start 6
Starting task 6 'call the tax accountant to undestand the next steps'.
Started 1 task.
You have more urgent tasks.
Project 'saas.taxes' is 0% complete (2 of 2 tasks remaining).

$ task

ID Active Age   Project    Tag     Description                                           Urg
 6      - 19min saas.taxes         call the tax accountant to undestand the next steps      5
 1         1h   saas       finance make a financial plan                                  1.8
 3         1h   saas       tech    buy the dns domain                                     1.8
 4         1h   saas       tech    buy a public ip                                        1.8
 2         1h   saas               decide a cool name                                       1
 5         1h   saas               definite an mvp                                          1
 7        19min saas.taxes         produce the documentation we need to register the ltd    1

7 tasks
```

Great now let's mark the task 6 as done:

```bash
$ task done 6
Completed task 6 'call the tax accountant to undestand the next steps'.
Completed 1 task.
The project 'saas.taxes' has changed.  Project 'saas.taxes' is 50% complete (1 of 2 tasks remaining).
```

Since we are using a todo app to remember things for us so we can forget them, we need to have a way to check the current status:

```bash
$ task summary

Project Remaining Avg age Complete 0%                        100%
saas            6      1h      14% ####
  taxes         1   19min      50% #############

2 projects
```

## The elephant in the room: urgency

So far we did not mention the urgency level in taskwarrior that you can see in the last column of the `task` command.

This is one of my favorite and most important concepts in taskwarrior: each task has an urgency level that is calculated automatically for you so you can focus on the most important tasks first.

To start familiarizing with it, let's start a task:

```bash
$ task start 2
Starting task 2 'decide a cool name'.
Started 1 task.
You have more urgent tasks.
Project 'saas' is 0% complete (5 of 5 tasks remaining).

$ task

ID Active Age   Project    Tag     Description                                    Urg
 2      -  1h   saas               decide a cool name                                5
 1         1h   saas       finance make a financial plan                           1.8
 3         1h   saas       tech    buy the dns domain                              1.8
 4         1h   saas       tech    buy a public ip                                 1.8
 5         1h   saas               definite an mvp                                   1
 6        39min saas.taxes         produce the documentation we need to register     1
                                   the ltd

6 tasks
```

Did you notice the urgency level of the task 2? After our start command it's now `5`.

How this urgency level is calculated? everything in taskwarrior could give (or remove) urgency points to a task.
No need to list all them for the moment, you just need to be aware that any property of a task will affect the urgency level

And the great part is that this is completely configurable, you can change the urgency calculation to fit your needs (we will talk about this in the next post of this guide).

Let's see togheter why our task 2 has an urgency level of `5` and to do so let's use a new command: `task info`:

```bash
$ task info 2

Name          Value
ID            2
Description   decide a cool name
Status        Pending
Project       saas
Entered       2025-01-15 22:52:52 (1h)
Start         2025-01-16 00:32:00
Last modified 2025-01-16 00:32:00 ()
Virtual tags  ACTIVE PENDING PROJECT READY UNBLOCKED
UUID          73fd37b5-6f5a-430e-a5c9-1c35edbbc016
Urgency       5

    project      1 *    1 =      1
    active       1 *    4 =      4
                            ------
                                 5

Date                Modification
2025-01-15 22:52:52 Description set to 'decide a cool name'.
                    Entry set to '2025-01-15 22:52:52'.
                    Status set to 'pending'.
2025-01-15 22:52:55 Project set to 'saas'.
2025-01-16 00:32:00 Start set to '2025-01-16 00:32:00'.
```

For this particular task, the score of `5` is the sum of `1` 'cause it's part of a project and `4` because it's an active task.

Obviously, the urgency level will move up and down the tasks when we list them, so you can always focus on the most important tasks.

Now let's see another factor that will affect the urgency level.

## Dependencies

This is one of my favorite urgency factors: in a complex project, you may have tasks that are dependent on other tasks, right?
Let's see how this works in taskwarrior.

But before that, we have an active task, right? Let's check it using the `active` command:

```bash
$ task active

ID Started    Active Age  Project Description
 2 2025-01-16   1s   1h   saas    decide a cool name

1 task
```

We still need to decide the cool name of our pagerduty clone, I believe that `bringyourlaptopwithyou.com` or `bylwy.com` is a nice one.

Cool, let's mark our task as done and add a couple of new one:

```bash
$ task done 2
Completed task 2 'decide a cool name'.
Completed 1 task.
The project 'saas' has changed.  Project 'saas' is 20% complete (4 of 5 tasks remaining).

$ task 2 modify buy bylwy.com domain #before was a generic dns domain
Modifying task 2 'buy bylwy.com domain'.
Modified 1 task.
Project 'saas' is 20% complete (4 of 5 tasks remaining).

$ task add open the aws account project:saas.infra
Created task 6.
The project 'saas.infra' has changed.  Project 'saas.infra' is 0% complete (1 task remaining).

$ task add request company credit card project:saas.bank tags:finance
Created task 7.
The project 'saas.bank' has changed.  Project 'saas.bank' is 0% complete (1 task remaining).

$ task

ID Age  Project    Tag     Description                                           Urg
 1 2h   saas       finance make a financial plan                                  1.8
 2 2h   saas       tech    buy bylwy.com domain                                   1.8
 3 2h   saas       tech    buy a public ip                                        1.8
 4 2h   saas               definite an mvp                                          1
 5 1h   saas.taxes         produce the documentation we need to register the ltd    1
 6 4s   saas.infra         open the aws account                                     1
 7 4s   saas.bank  finance request company credit card                              1

7 tasks
```

Ok now it's the moment when we need to order our tasks.

The first intuitive step will be to make connection between the tasks, since some of them are dependent on others.

We need to first complete the documentation for our ltd so we can form our company and then request a credit card. With the credit card we can open an aws account and buy a public IP and a dns domain.

Let's translate this into taskwarrior:

```bash
$ task 2 3 modify depends:6
This command will alter 2 tasks.
Modifying task 2 'buy bylwy.com domain'.
Modifying task 3 'buy a public ip'.
Modified 2 tasks.
Project 'saas' is 20% complete (4 of 5 tasks remaining).

$ task 6 7 modify depends:5
This command will alter 2 tasks.
Modifying task 6 'open the aws account'.
Modifying task 7 'request company credit card'.
Modified 2 tasks.
Project 'saas.bank' is 0% complete (1 task remaining).
Project 'saas.infra' is 0% complete (1 task remaining).

$ task

ID Age  Deps Project    Tag     Description                                           Urg
 5 2h        saas.taxes         produce the documentation we need to register the ltd    9
 6 1h   5    saas.infra         open the aws account                                     4
 1 3h        saas       finance make a financial plan                                  1.8
 4 3h        saas               definite an mvp                                          1
 2 3h   6    saas       tech    buy bylwy.com domain                                  -3.2
 3 3h   6    saas       tech    buy a public ip                                       -3.2
 7 1h   5    saas.bank  finance request company credit card                           -3.2

7 tasks
```

Did you see what happened?

Immediately after we added the dependencies, the urgency level of the tasks changed.
The tasks that are dependencies for other tasks received more points since they are the prerequisites
for the other tasks and now have become the most important tasks.

The tasks that are dependent on other tasks received negative points because we can't do them until the other tasks are done.

## Next part

Are you enjoying taskwarrior, like I do, so far? I hope so.

In the next part (don't miss it) of this practical guide, we are going to talk about more advanced topics around sorting our tasks by urgency, adding due and schedule dates, creating customer reports, and using hooks to automate our taskwarrior experience.

Stay tuned!
