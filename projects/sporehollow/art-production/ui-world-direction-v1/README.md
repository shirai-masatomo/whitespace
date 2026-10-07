# UI/world direction v1 sources

Built-in image_gen only. User request in request.txt. Full prompts, reference roles and generated file paths in generation-records.json. originals contains unmodified generations, including superseded extraction/layout attempts. references contains adopted sprite enlargements and saved game screens; specs contains current source-document snapshots.

Rebuild review candidates: Python finalize.py (imports make_reviews.py then performs visual cleanup); then package.py to refresh manifest and QA. Requires Pillow/numpy. No game executable runs and no external API is called.

Native processing: alpha thresholding (never white color key), proportional nearest fit, 32-color palette, removal of isolated native pixels, preserved canvas/anchors, UI frame masks, provisional tree layers, corrected READY star centers. Storyboards use connected-alpha silhouette extraction to avoid clipping neighbouring poses. They are NOT runtime animation frames.

All output goes to art_delivery/ui_world_direction_v1. Existing formal assets are read-only references. Generated originals are not a deliverable substitute for the candidate PNGs. Further native pixel finishing/layer separation is pending design adoption.

