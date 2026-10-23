# エグゼクティブサマリ  
本ガイドでは、RTX 4070 SUPER（VRAM 12GB）環境下でComfyUIを用いて成人向けCG（美少女ゲームCG）を制作する手順とノウハウをまとめる。**プロンプト設計例（日本語→英語変換例）**や**ネガティブプロンプト**、**局所修正・衣装変更・ポーズ変更・表情差分・同一人物再現**のテンプレート例を提示し、期待効果と注意点を解説する。**ComfyUIワークフロー**（ノード構成、主要設定値、マスク作成法）や**制作手順**（素材準備→プロンプト設計→ControlNet/OpenPose/LoRA/LoCon/HiResFix/Inpainting→バッチ生成→選別→微調整→最終調整）も図示し、各工程での所要時間・VRAM目安を示す。**失敗例と改善策**では、手指・顔・衣装・背景の破綻例を列挙し、プロンプト修正・マスク活用・モデル切替等で対処する方法を説明する。さらに、**成人向け利用に適したモデル選定**（Animagine, DreamShaper, Juggernaut, RealVis, FLUXなど）と各モデルの特性・NSFW対応・ライセンス・商用利用可否、DLsite/Steamの規約留意点（AI生成作品区分・申告義務）を整理する。**ケーススタディ**として①衣装差分（普段着→水着）、②ポーズ変更（立ち→座り）、③夜のベッドイベント（照明・雰囲気調整）の3例を示し、モデル・プロンプト・ノード構成・設定値・マスク例・生成結果の評価基準と改善ループを解説する。**大量生成・自動化**ではバッチ処理やLoRA活用、メタデータ管理の手法、VRAM節約テクニックを紹介し、生成データ管理用のCSV/JSONテンプレート例も示す。最後に**セキュリティ・倫理・法的注意**として、成人確認・未成年禁止・プラットフォーム規約順守・ローカル隔離環境での運用・生成物の公開時表示方法を具体的にまとめる。各項目はHugging Faceモデルカード、ComfyUI公式ドキュメント、Steam/DLsite公式情報等を参照して裏付けている。  

## 1. プロンプト設計（局所修正・衣装変更・ポーズ変更・表情差分・同一人物再現）  
画像生成では、**日本語の指示**を英語タグ形式に的確に変換することが重要。例えば「28歳の金髪ロング女性、図書館で本を持ち右手を振っている（美少女ゲーム風）」という要望を、Animagine XL 4.0向けの英語プロンプトにすると次のようになる。  

```  
Positive Prompt:  
1girl, solo, adult woman, 28 years old, long blonde hair, blue eyes, gentle smile, holding a book in left hand, waving right hand, library, bookshelves, anime visual novel style, masterpiece, high score, great score  
Negative Prompt:  
lowres, bad anatomy, bad hands, text, error, missing finger, extra digits, fewer digits, cropped, worst quality, low quality, watermark, signature, blurry  
```  

ここで、**ネガティブプロンプト**には「低解像度」「解剖学的異常」「悪い手部」「ぼやけ」など定番キーワードを列挙する。Animagine公式でも上述のようなネガティブワードが推奨されている。プロンプトは英語タグ形式（カンマ区切り）とし、モデルの**指示理解範囲**に合わせて具体的に記述する。日本語で大まかに書いた要望をChatGPT等で英語プロンプトに自動変換する手順がおすすめで、言語バリアによる品質低下を避けられる。  

各タスクごとのプロンプト例と留意点を以下に示す。  

- **局所修正（Inpainting）**: 生成画像の一部を修正する。マスクで修正範囲を指定し、同一画風・同一人物を保ちつつ部分を再生成する。例えば「元画像の顔立ち・体型を維持しつつ、視線をこちらに向け、微笑顔にする」では、顔をマスクし、次のようなプロンプトを使用する。  
  ```  
  Positive Prompt:  
  same appearance, same hairstyle, from original image, female, gentle smile, looking at viewer, anime CG style, masterpiece, high score  
  Negative Prompt:  
  (as above: bad anatomy, deformed, etc.)  
  ```  
  **効果・注意**: 顔修正では「gentle smile」「looking at viewer」など表情指定語を追加し、微細な変更を狙う。マスク範囲は顔の輪郭ぎりぎりまで慎重に取り、髪や背景が欠けないよう注意する。**注意点**として、プロンプトだけで表情変更できない場合が多いので、精度が必要ならControlNetの**顔ランドマーク**やInpainting専門モデル（後述）を併用する。  

- **衣装変更**: 主人公の服装を別衣装に変更する。元画像の服部分をマスクし、新しい衣装をプロンプトに指定する。例えば「白いブラウスの女性をエレガントなサテンのナイトウェアに変更、暖かな寝室照明で座らせる」という要望では、衣装とポーズをプロンプトで詳細指定する。  
  ```  
  Positive Prompt:  
  1girl, same girl, long blonde hair, blue eyes, elegant satin nightgown, sitting on bed edge, gentle smile, warm bedroom lighting, romantic atmosphere, anime CG style, high quality  
  Negative Prompt:  
  lowres, bad anatomy, bad hands, deformed, watermark, blurry, etc.  
  ```  
  **効果・注意**: 「satin nightgown」など具体的な衣装名や素材を入れる。背景の要素（ベッド、暖色照明など）もプロンプトに書くと設定を統一しやすい。マスクは衣装範囲に正確に適用し、髪型や肌の領域を誤って削らないようにする。衣装変更は手指や肌色との境界が不自然になりやすいので、後述の**局所修正工程**で境界を修復することがある。  

- **ポーズ変更（OpenPose制御）**: 立ち姿勢から別のポーズへ変更する場合、ControlNetのOpenPose機能を使う。まずOpenPoseで目標ポーズの骨格画像を作成し、それを入力にして生成する。例えば「同じ女性キャラを椅子に腰掛けたポーズにする」は、椅子に座るポーズ骨格画像をOpenPoseで作成し、次のように入力する。  
  ```  
  # まず姿勢データ（骨格画像）を用意しComfyUIのLoad Imageで読み込む  
  Positive Prompt:  
  1girl, same girl, sitting posture, long blonde hair, blue eyes, gentle expression, (制服 style outfit or specify clothing), interior scene, anime CG style, masterpiece  
  Negative Prompt:  
  lowres, bad limbs, bad hands, cropped, etc.  
  ```  
  **効果・注意**: OpenPose骨格マップをControlNetに入力することで、人物の手足・体勢を正確に制御できる。マスクは不要だが、衣装や顔の整合性を保つため、必要に応じて「same girl」や「masterpiece」タグを入れて精度を高める。**注意点**として、プロンプトだけでは細かい表情や手の形状を保証できないため、生成後に手指が崩れることがある。手指崩れ対策としては、次節の失敗例で述べる**Inpainting**や**IP-Adapter**で部分修正する。  

  のように、OpenPoseは体18点＋顔70点＋手21点＋足6点の骨格検出で制御する。ComfyUIの公式例では、OpenPose骨格を**条件入力**にすることで、望むポーズに合わせてリアルな人物像が生成できる。下図は制御入力（骨格）と生成出力の例。  

   *図：OpenPoseで作成した骨格マップ（ComfyUI入力例）*  

   *図：ComfyUIでOpenPose制御後に生成された女性キャラクター*  

- **表情差分**: 同じキャラを微妙に違う表情で複数作る場合。例えば「同一キャラを困惑顔、照れ顔、笑顔に変更」は、それぞれに応じた感情語をプロンプトに入れる。  
  ```  
  # 照れ顔の例  
  Positive Prompt:  
  1girl, same girl, pink blush, embarrassed expression, gentle smile, (scene or background), anime CG style, masterpiece  
  Negative Prompt:  
  bad anatomy, deformed face, etc.  
  ```  
  **効果・注意**: 「embarrassed expression」「blush」「confident expression」など感情語を使う。顔のみをマスクしてInpaintingする場合、**局所修正**機能を使うと効果的。ただし頭部以外が不自然にならないよう背景や服の情報はマスク外に置く。  

- **同一人物再現**: CG制作では同じキャラクターを複数シーンで維持する必要がある。ComfyUIでは**LoRA/LoCon**や**IP-Adapter**を使って特定キャラの特徴を定義し、再現性を高められる。プロンプトテンプレートには常にキャラ名・特徴（髪型・目の色・身長等）と画風タグを入れ、制御モデルも活用する。例えば「主人公（長身細身の茶髪女子）を別背景で再現」なら、  
  ```  
  Positive Prompt:  
  1girl, [character name], tall slender woman, brown hair, (main outfit or feature), [scene], anime style, detailed eyes, masterpiece  
  Negative Prompt:  
  (standard negatives)  
  ```  
  **効果・注意**: プロンプトで同一人物であることを強調するため、名前やキーボイントを使う。さらに**IP-Adapter**や**LoRA**でキャラモデルを用意すれば、一貫性が上がる。複数画像を生成する際は、固定シードやプロンプトテンプレートを使うことで別シーンでも顔立ちがぶれにくくなる。とはいえ安定性は保証できないため、異なるモデルに切り替えたり、完全一致が必要なら手動修正やCG重ね合わせも検討する。  

## 2. ComfyUIノード構成と設定  
### （1）基本ノード構成  
ComfyUIでは**ビジュアル・プログラミング**でワークフローを構築する。基本的なテキスト→画像生成フローは、主に以下のノードで構成される。  

- **Load Checkpoint**: 使用モデル（Animagine, Juggernautなど）のチェックポイントを読み込む。  
- **KSampler**: 実際の画像生成を行うノード。ステップ数やSampler（DPM++ Karras等）を設定。  
- **VAE Decode**: 潜在空間から画像をデコードする（SDXL系では通常不要または組み込み）。  
- **Save Image**: 生成画像をファイル保存。  

基本的なtxt2imgワークフローは、プロンプトを入力する**Text Prompt**ノードとネガティブ用ノード、上記モデル・Samplerノードをつなぎ、最後に**Save Image**で出力する。主要パラメータ例：サンプル数20～30、CFGスケール7～9、Seed固定で再現性確保。サンプラーは**DPM++ 2M Karras**がSDXLで推奨される例。解像度は標準1024×1024まで、下図の例では**768×768**で概ねVRAM 8GB程度を要する（※後述のVRAM節参照）。  

```mermaid
flowchart LR
    subgraph txt2img
      P[Text Prompt] --> KS[KSampler (txt2img)]
      KS --> SD[VAEDecode] --> O[Save Image]
    end
```
*図：基本的なテキスト→画像生成ワークフローの概略*  

### （2）Inpainting（局所修正）ワークフロー  
局所修正時は**Load Image**ノードで元画像を入力し、**Mask Editor**で修正箇所を指定。マスクは透明度（alpha）チャネルか手書きで作成し、**VAE Encoder (for Inpainting)**で潜在にエンコードする。以降、修正部分のみ生成し、元画像に合成する。  

```mermaid
flowchart LR
  LI[Load Image (元画像)] --> ME[Mask Editor (修正領域)] --> VE[VAE Encode (Inpaint用)]
  VE --> KS2[KSampler (Inpainting)]
  KS2 --> VD[VAE Decode] --> SI[Save Image (修正後画像)]
```
*図：Inpaintingワークフロー（局所修正例）*  

- **マスクの作成**: Mask Editorや外部ツールで修正領域を白、他を黒で塗る。マスクはなるべく境界を滑らかにし、余計な領域を塗り込まない。  
- **モデル選択**: Inpaintingには専用モデルを使うと効果的。512×512専用Inpaintingモデル（例: `512-inpainting-ema.safetensors`）はSDXL標準モデルより自然な修正が可能。通常のSDXLモデルでもInpaintingはできるが、境界ぼかしやアーティファクトが目立ちやすい。  
- **設定例**: ステップ数は25～30、CFGは低め（3～5）に設定し、マスク領域のみ適度に変化を与える。アップスケーリングは最終的に**HiRes Fix**や**Upscale**ノードで行う。  

ComfyUI公式チュートリアルでも、Inpainting専用モデルの使用が推奨されている。マスク編集後はプロンプトやシードを調整し、何度か繰り返すことで最適化する。  

### （3）ControlNet・OpenPoseノード構成  
ポーズ制御では、**Load ControlNet Model**でOpenPoseモデル（例: `control_v11p_sd15_openpose_fp16.safetensors`）を読み込み、**Apply ControlNet**ノードに骨格画像を入力する。先述の通りOpenPose骨格は「18点ボディ＋顔70＋手21＋足6」という構造マップを生成し、生成の条件として使う。ComfyUIではこの**Apply ControlNet**ノードが主要な役割を担う。設定値は通常、**Scale**（ControlNetの影響度）を1.0、**Weight**を1.0にして骨格を強く反映させる。  

### （4）LoRA/LoConによるキャラ固定  
同一人物再現には、**LoRA/LoCon**適用ノードをワークフローに組み込み、キャラLoRAをロードしておく。Load Checkpointの隣にLoRAノードを置き、プロンプトと同時にキャラLoRA名を渡す。これにより、複数CG間でキャラ特徴の一貫性を高められる。  

### （5）主要パラメータの例  
- **サンプル数 (Steps)**: 通常20～30。多すぎると変化微小、少なすぎると荒れる。20-25が高速で安定。  
- **CFG（ガイダンススケール）**: 5～9。数値を上げるほどプロンプト忠実度が高いが、創造性が減る。顔や構図固定は高め、雰囲気重視はやや低めに調整。  
- **Sampler**: SDXL推奨は**DPM++ 2M Karras**または**Karras variants**。SD1.5系とは異なるので各モデルカード推奨Samplerを確認。  
- **Seed**: 固定して再現性を取るか、乱数でバリエーションを得るか用途に応じて。  
- **解像度**: RTX4070(12GB)では最大1024×1024推奨。768×768なら余裕がある。2回生成して合成（HiRes Fix）も可能。  

## 3. 制作ワークフロー（工程と設定例）  
成人向けCG制作の一般的な工程を以下に示す。各工程での例設定値と所要時間・VRAM目安も併記する。  

1. **元画像・素材準備** (数分～):  
   - キャラクター立ち絵や参考画像を用意。スキャン・クリップスタジオ作画等の手描き素材もOK。  
   - 解像度はあとでComfyUI生成に合成しやすいもの（例: 1024×1024以上）を用意。  
   - 20MB程度のPNG一枚であればVRAM 0.5GB未満で読み込み可能。  

2. **プロンプト設計** (10分～):  
   - 上述のテンプレート例をもとに、英語プロンプトとネガティブプロンプトを作成。  
   - Codex/ChatGPTで日本語→英語変換すると効率的。  
   - 複数シナリオ（衣装、水着、夜の照明、等）ごとにプロンプト案をリストアップ。  

3. **初回生成（txt2img）** (1～2分/枚, VRAM 8GB前後):  
   - ComfyUIで**Load Checkpoint**にモデル（例: Animagine XL 4.0）、**Text Prompt**に準備したプロンプト、**KSampler**に設定（Sampler=DPM2M,Karras; Steps=25; CFG=7; Size=768×768; Seed任意）を入力して実行。  
   - 生成画像を確認し、キャラの顔・構図・大まかな雰囲気を評価。  
   - （例: 768pxならVRAM約8GB使用。1枚生成に2分程度。）  

4. **ControlNet/OpenPose適用（ポーズ変更時）** (2～3分/枚, +VRAM 1GB):  
   - 骨格画像を作成し、ControlNetノードに接続。プロンプトは上記テンプレートを使用。  
   - 2パス生成の場合は、まず低解像度で基本構図を生成し、次に高解像度でディテールを追加（実行時間+）。  
   - **VRAM**: 768pxなら約9GB（ControlNetモデル追加で+1GB程度）。  

5. **Inpainting処理（局所修正）** (1分/枚, +VRAM 0.5GB):  
   - 修正箇所を**Mask Editor**で指定し、VAEエンコーダを通じてInpaintingノードに接続。  
   - プロンプトは元画像の要素を保持するよう記述し、変更したい要素のみ指定。  
   - 必要なら複数回繰り返し。  
   - **VRAM**: 約9GBで済む（Inpainting専用モデル使用時は同程度）。  

6. **表情・衣装追加編集** (1分/枚):  
   - 追加で必要な表情差分や衣装微調整がある場合、該当箇所を再度マスク→Inpaintする。  
   - 例: 顔だけ別表情にしたいときは顔マスク、服だけ変更したいときは服マスク。  

7. **バッチ生成** (総合時間：数十～数百枚):  
   - 複数パターンを一括生成する場合、同じワークフローで**For Loop**やスクリプト機能を使う。  
   - LoRAをキャラに適用してキャラ再現性を高め、プロンプトテンプレートをコピーして大量生成。  
   - 出力時に**Save Image**で連番保存し、メタデータ（プロンプト/Seed/モデル名）をファイル名やCSV/JSONに記録する。  

8. **選別・微修正** (人手):  
   - 生成画像からクオリティ良好なものを選ぶ。  
   - 手・表情・構図に問題があれば、その画像を素材として上記工程（ControlNet/Inpaint）で再修正する。  
   - 例: 生成時に手が崩れた場合は再度Inpaintや別手法で整え、表情が不自然なら顔差分生成を試みる。  

9. **最終調整・高解像度化** (各1～2分/枚):  
   - SDXLの**HiRes Fix**機能で高解像度化：粗画質版を768→1024などに上げ、細部を再生成。  
   - 必要に応じてLightroom等で色調補正も。  

各工程では、ComfyUIのノード構成と設定例を上記の通り適用する。処理時間はステップ数・解像度・VRAMによって増減するが、RTX4070で768px・30ステップ程度なら1枚あたり数分以内、1024pxに拡大すると5分前後になる。  

## 4. 失敗例と改善策  
AI生成では多くの典型的失敗が起こる。以下に例を挙げ、プロンプト・ノード・モデル変更などで対処する方法を示す。  

- **手指の破綻**: 指の数が合わない、途中で消失、変形など。  
  **改善**: ネガティブプロンプトに`bad hands, missing finger, extra digits`を追加する。ControlNet（OpenPose）の手部詳細モデルや、指の形を描いたPoseを使う。最終手段で該当領域をマスクし**Inpainting**する。IP-Adapterで腕・手を補正する方法も有効。  

- **顔の破綻**: 目が左右非対称、口が変形、輪郭が崩れる。  
  **改善**: ネガティブに`deformed, face asymmetry, ugly`などを追加する。顔部分を小さくCroppingして別生成し、後で合成する方法もある。あるいは高品質な顔ディテール用モデルに切り替えたり、LoRAで顔特徴を安定化させる。  

- **衣装の不自然さ**: 衣装が破ける、肌透け、光沢がおかしい。  
  **改善**: 衣装のマスクを正確に切り出し、Inpainting用のプロンプトで衣装素材・光沢を細かく指定する。例えば「satin」「lace」「embroidery」など具体的な材質ワードを追加。また、衣装部分のみ専門に訓練されたモデル（例: アナログ風LoRA）を使う。  

- **同一人物性の喪失**: 別の顔や体格になってしまう。  
  **改善**: これにはキャラ固有LoRAやIP-Adapterが効果的。**Prompt**に再現したいキャラ名・特徴を常に入れ、**モデル**は一貫した物を使用する。異なるモデルで生成した場合は、それぞれキャラを登録したLoRAを適用して統一する。   

- **背景の崩壊**: 繰り返しパターン、文字が混入する、風景が歪む。  
  **改善**: ネガティブに`text, watermark, signature, error`を入れる。背景だけ別に生成して合成するか、簡単な背景は先に作っておきマスクせず生成時固定する。場合によっては背景にもControlNet（Depth/線画）を使って構造を安定させる。  

これらの対処には、**プロンプトの調整（具体性・否定語追加）**、**モデル変更（Inpainting専用・Refiner系モデル）**、**マスク再指定**など複合的に試すのが常套手段である。また、ComfyUIのチュートリアルでは「プロンプトをより具体的に」「種子を変えて複数試す」「マスクを編集して再生成」などの反復改善策が推奨されている。  

## 5. モデル選定と商用利用・規約注意点  
成人向け表現で利用可能な代表的モデルと、その特徴・NSFW対応・ライセンス・商用利用可否をまとめる。主にHugging FaceのモデルカードやComfyUIドキュメントを参照する。  

| モデル名              | 特徴・画風            | ライセンス・商用利用         | NSFW対応                 | 備考 |
|-----------------------|----------------------|----------------------------|-------------------------|------|
| **Animagine XL 4.0**  | 日本語美少女系(SDXL)| CreativeML OpenRAIL++ (商用可) | レーティングタグ(`safe`,`sensitive`,`nsfw`,`explicit`)あり | Cagliostro Lab製、アニメCG特化モデル。露骨なポルノ以外の成人表現まで柔軟に対応可能。 |
| **DreamShaper XL**    | アニメ・イラスト系 (SDXL)| OpenRAIL++ (商用可)  | 特記なし (おそらく成人表現可) | Lykon氏製、イラスト・キャラ多めのfine-tuneモデル。商用利用可能。|
| **Juggernaut XL v9**  | フォトリアル (SDXL)  | CreativeML OpenRAIL-M| 特記なし (成人表現可)  | RunDiffusion製、写実的CG向け。8GB GPUで安定動作。商用可。 |
| **RealVisXL v5.0**    | フォトリアル (SDXL)  | OpenRAIL++ (商用可) | SFW/NSFW両対応 (高品質) | SG161222製、リアル写真風CG。成人CGも「十分な品質で生成可」と明記。商用可。 |
| **FLUX.1 [dev]**      | 最高峰生成 (Diffuser)| FluxDev Non-Commercial (商用×)| 特記なし (成人表現可能) | BlackForest製、12Bモデルの高品質生成器。非商用のみ（商用利用不可）。現時点でローカル実行可（ComfyUIノード対応）。 |

各モデルとも**商用利用ライセンス**を確認すること。Animagine・DreamShaper・RealVisはOpenRAIL++で商用利用可。JuggernautはOpenRAIL-Mで商用可。**FLUX.1-dev**のみ商用不可のためゲーム制作には利用できない。成人向け表現もモデル性能によって得意不得意があるので、テスト生成で肌の自然さやキャラ再現性を評価する。  

SteamやDLsiteの申告規約にも注意。Steamでは**コンテンツサーベイ**でAI生成物を申告し、一般コンテンツと同等の審査を受ける必要がある。特に「プレ生成（開発時生成）コンテンツ」には通常コンテンツと同様の規定が適用される。なお、**AIを使って成人向け画像をプレイ中に生成する機能はSteamでは許可されていない**（開発時に生成した静的素材のみ可能）。また、**未成年者の性的描写はどのプラットフォームでも違法・禁止**であり、全工程で回避必須である。  

DLsiteの場合、**AI補助作品**に関するガイドラインがあり、「作品のメインにAI画像を使用したら『AI生成作品』扱いになる」とされている。つまり、主要キャラのCGをComfyUIで生成した場合はAI生成区分で登録する必要があり、販売フロアも分離されるリスクがある。一方、背景や挿絵など補助的にAIを使った場合は「AI一部利用」として分離が緩和される可能性があるが、判断は運営次第で厳しい場合もある。**FANZA**はやや緩やかで、AI補助なら通常扱い、生成画像を線画に使った場合は「一部利用」として受け付けられるとされる。いずれにせよ、販売前にプラットフォーム規約を確認し、必要なら事前申請・説明を行うことが望ましい。  

## 6. 実践ケーススタディ  

### ケース1：衣装差分（普段着→水着）  
- **概要**: 普段着の立ち絵をマスクで水着に変更し、夕日のビーチ背景に置く。  
- **使用モデル**: Animagine XL 4.0（アニメ調）  
- **ノード構成**:  
  1. Load Image（元立ち絵）→ Mask Editor（服部分をマスク）→ VAE Encode (Inpainting)  
  2. Load Checkpoint (Animagine XL 4.0) & VAE Decode（Inpainting生成）→ KSampler → Save Image  
- **プロンプト（英語）**:  

  ```  
  # 元の服を水着にするプロンプト例  
  Positive Prompt:  
  same girl, long blonde hair, blue eyes, swimwear, elegant orange bikini, smiling, sunset beach, soft lighting, anime visual novel CG style, masterpiece, high score  
  Negative Prompt:  
  lowres, bad anatomy, bad hands, deformed, blurry, watermark, ugly, worst quality  
  ```  

- **設定値**: KSampler (Sampler=DPM2M-Karras, Steps=25, CFG=7.5), 768×768, Seed固定。マスクは服だけ白塗り。  
- **期待効果**: マスク範囲の服がオレンジ色のビキニに変わり、背景には夕日が映えたビーチ風景が現れる。キャラの体型・顔立ちは維持。  
- **改善ループ**: もし手や肌境界が怪しい場合、手に別マスクをかけてInpainting修正。背景がおかしい場合はプロンプトで「sunset, ocean」で補強する。また、別モデル（例：DreamShaper）で生成し比較し、好みの方を採用する。  

### ケース2：ポーズ変更（立ち→座り）  
- **概要**: 同一キャラを椅子に座らせ、横顔で見返る構図に変更。  
- **使用モデル**: RealVisXL v5.0（フォトリアルSDXL）  
- **ノード構成**:  
  1. OpenPoseで座りポーズ骨格画像作成→ Load ControlNet Model (OpenPose)  
  2. Load Image（骨格画像）+ Text Prompt → Apply ControlNet → KSampler → VAE Decode → Save Image  
  3. ※必要に応じて2パス生成（1pass: majicmixRealistic_v7で基本図→ 2pass: japaneseStyleRealistic_v20で詳細仕上げ）  
- **プロンプト（英語）**:  

  ```  
  # 椅子に座るポーズのプロンプト例  
  Positive Prompt:  
  1girl, same girl, long blonde hair, blue eyes, sitting on wooden chair, looking back over shoulder, casual outfit, warm indoor lighting, photorealistic style, masterpiece  
  Negative Prompt:  
  lowres, bad anatomy, bad hands, blurred, cropped, worst quality  
  ```  

- **設定値**: ControlNet Weight=1.0, Scale=1.0、KSampler（Steps=30, CFG=8）。座りポーズ骨格画像をLoad Imageに入力。  
- **期待効果**: 骨格に沿った座り姿勢のキャラ生成。横顔なので顔の左右対称が不安定になりやすいが、ControlNetが姿勢を固定し大崩れを防ぐ。背景は室内で、Casual outfit（普段着）の指示で安定。  
- **改善ループ**: もし顔や手が崩れたら、元画像からキャラだけ抜き出し、座りポーズに誘導して再生成する（別seedも試す）。又は1pass生成画像のVAE Decode後に顔マスクをかけて再Inpaintし、顔修正する。  

### ケース3：夜のベッドイベント（照明・雰囲気調整）  
- **概要**: 昼間の立ち絵を、暖色照明の寝室シーンに変換し、ベッド端に座るポーズにする。  
- **使用モデル**: DreamShaper XL 1.0（柔らかい雰囲気のSDXL）  
- **ノード構成**:  
  1. Load Image（元立ち絵）→ Mask Editor（背景全体をマスク）→ VAE Encode  
  2. 新規テキスト生成：Load Checkpoint(DreamShaper) → Masked KSampler → VAE Decode → Save Image  
  3. 背景なしのキャラマスク版と、シーンとキャラ両方を生成する2passでも可。  
- **プロンプト（英語）**:  

  ```  
  # 寝室で座るシーンのプロンプト例  
  Positive Prompt:  
  1girl, long blonde hair, blue eyes, silk nightgown, sitting on edge of bed, gentle smile, warm bedroom lighting, moonlight through window, floral bedding, detailed eyes, anime style CG  
  Negative Prompt:  
  lowres, bad anatomy, bad hands, textual, blurry, low quality  
  ```  

- **設定値**: Sampler=DPM2M, Steps=25, CFG=7. 首尾一貫したシーンのために、背景・照明・オブジェクト（窓、月光、花柄ベッド）の語をプロンプトに含める。  
- **期待効果**: 元画像のキャラを保ちながら、雰囲気の異なる夜室内シーンを生成。暖かい照明と窓から差す月光で情緒的になる。衣装はシルクのナイトウェアに変わり、夜のベッドイベントらしい緊張感を演出。  
- **改善ループ**: 目のハイライトや表情が暗すぎたり崩れた場合、顔だけ明るい笑顔を別プロンプトで生成し合成する。部屋の明暗が不自然な場合は照明語（warm light, soft shadow）を追加する。  

各ケースとも、**生成結果の評価基準**は「キャラの特徴維持」「破綻の有無」「雰囲気や衣装の一致度」で判断する。満足できなければ上記プロンプト・マスク・モデルを組み合わせて改良を繰り返す。  

## 7. 大量生成・自動化の注意点  
大量のCG候補を生成するには、**バッチ処理とテンプレート化**が重要。ComfyUIでは以下の方法を使うと効率的：  
- **ループ機能**: ComfyUIのPythonモードやForノードで、複数種子・パラメータの組み合わせを自動で実行できる。  
- **LoRA活用**: キャラ固定にはLoRAが有効だが、LoRAはVRAMを若干消費する（約0.5GB）。複数のLoRAを切り替える場合はマクロノードで手動切替を自動化する。  
- **メタデータ管理**: 生成時にファイル名やサイドcarで`prompt, seed, model`などを書き出し、自動記録する。例えば、出力ファイル名を`CharacterX_Beach_Sunset_Seed1234.png`のようにしたり、CSV/JSONに全プロンプトとシードを記録する。  

**VRAM節約**: 12GBではSDXLモデルに余裕がないため、64bitやFP16モデルを使用。`--medvram`オプションや`VAE offload`でメモリを節約できる。高速生成にはLoRAs精度を落とした**LoCon**使用や、CFGI(1パス→2パス)で途中から処理を軽くする方法もある。WillItRunによれば、RealVisXL V5.0 768×768出力で約7.8GB、1024×1024でも約8.0GBで動作可能。Juggernaut v9も8GBで快適動作するので、RTX4070(12GB)なら標準解像度で十分対応可能である。  

以下は生成物管理用の例（JSON形式）のテンプレート例：  

```json
[
  {
    "filename": "Event1_Beach_Sunset.png",
    "model": "Animagine_XL_4.0",
    "seed": 12345678,
    "prompt": "1girl, ... anime visual novel style ...",
    "negative_prompt": "lowres, bad anatomy, ...",
    "size": "768x768"
  },
  {
    "filename": "Event1_Beach_Sunset.png",
    "model": "Animagine_XL_4.0",
    "seed": 87654321,
    "prompt": "... same ...",
    "negative_prompt": "...",
    "size": "768x768"
  }
]
```  

## 8. セキュリティ・倫理・法的注意  
- **成人確認・年齢制限**: 制作・販売するゲームは成人向けコンテンツであるため、プレイヤーが18歳以上であることを確認する仕組みを設ける（Steamでは成人向けフラグ設定が必須）。**未成年者を性的に描写することは法的に厳禁**なので、プロンプトに年齢明示(18歳以上)や子ども禁止キーワードを含めてガードする。  
- **プラットフォーム規約**: Steamでは前述のAI申告義務に加え、成人向け（AR職：High）として出す場合は該当サーベイで「裸、性行為、官能的シーン」を全て正確に申告する。DLsiteでは前述の「AI生成作品扱い」や「AI素材使用」ルールに注意し、必要な表示を行う。  
- **コンテンツ規制**: 各国法規を遵守する。特に**児童ポルノ規制**に反するような生成は絶対に行わない。プライベート/購入済み素材以外の著作権画像や他者のイラストを勝手に流用するのもNG。  
- **実行環境の隔離**: 安全のためComfyUIは**完全ローカル環境**で実行する。インターネット接続を切り、外部APIを呼び出さないようにすることで情報漏洩や不正アクセスのリスクを防ぐ。生成済みCGデータも社外秘やパスワード付きフォルダで管理し、関係者以外に漏らさない。  
- **公開時の表示・申告**: 商用作品にAI生成CGを使用した場合、Steamでは**Content Survey**で明記、プロモーション資料やクレジットに「AI技術による生成を用いたCGを含む」等の注記を推奨する。DLsiteでは購入者がAI生成であることを認識できるようタグや説明に明示しよう（例：「一部AIによる作画」）。  

以上の各項目を遵守しつつ、ComfyUIの柔軟なワークフローを活用すれば、商用同人ゲームのCG制作にも堅実に応用できる。モデルカードやComfyUI公式ドキュメントを参考に、品質とルールを両立させた制作を心がけよう。  

**参考資料:** Hugging Faceモデルカード（Animagine, DreamShaper, Juggernaut, RealVis, FLUXなど）、ComfyUI公式ドキュメント、DLsite/FANZA運営報告、Steamworksサーベイガイドなど。 (使用画像はComfyUIドキュメントより)