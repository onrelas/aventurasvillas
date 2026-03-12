# Blog Automation (Aventuras Villas)

## What this adds
- Topic queue
- Draft generator for twice-weekly cadence
- QA checker for CTA + hero + baseline depth

## Run
```bash
python3 blog/automation/blog_automation_run.py
python3 blog/automation/blog_qa_check.py
```

## Workflow
1. Generate draft from queue
2. Expand draft into full warm-host article
3. Move draft to `blog/posts/` and add card to `blog/index.html`
4. Run QA check
5. Commit + push
