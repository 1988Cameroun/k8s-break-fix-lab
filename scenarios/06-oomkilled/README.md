# 06 · OOMKilled: the memory limit is too small

**Level:** medium · **Namespace:** `lab-06`

## The ticket

> `image-resizer` keeps restarting. The logs just stop mid-sentence with no error,
> no stack trace, nothing. The developers swear the code hasn't changed and that
> the service needs about **150 MB** of working memory to process an image.

## Your goal

- `image-resizer` runs without restarting.

## Rules

- Don't change the application's memory usage (`WORKING_SET_MB` stays at 150).
  The developers are right about how much memory it needs.
- Keep a memory limit. Unbounded containers can starve their neighbours.
