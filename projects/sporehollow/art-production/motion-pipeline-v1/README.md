# 採用後の動作加工

内蔵画像生成の追加動作原画と、採用済みの静止・特殊キーから正式PNGを組み立てる。build.pyに対象のdesign IDを指定。tamerのみ納品・実装IDはanimal_tamer。build_special_reviews.pyは対象実装IDを指定する。各キャラクターの原画とプロンプトは隣接する*-motion-v1。

通常RGBA、二値透過、共有パレット、nearest、左右反転したアンカーを保つ。独立武器・舌のソケットはmanifestに記録。確認GIF・シートは実ゲーム検証ではない。gameコード、UID、能力値を編集しない。
