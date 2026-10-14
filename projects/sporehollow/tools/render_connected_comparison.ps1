param()
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
$dir=Join-Path $root 'review/current/connected-rocks'
$font=[Drawing.Font]::new('Yu Gothic UI',14)
$small=[Drawing.Font]::new('Yu Gothic UI',11)
$ink=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(48,61,47))
function ImageAt($g,$file,$x,$y,$width=0){
 $i=[Drawing.Image]::FromFile((Join-Path $dir $file))
 try {if($width -eq 0){$g.DrawImageUnscaled($i,$x,$y)}else{$g.DrawImage($i,[Drawing.Rectangle]::new($x,$y,$width,[int]($i.Height*$width/$i.Width)))}}finally{$i.Dispose()}
}
$b=[Drawing.Bitmap]::new(780,235);$g=[Drawing.Graphics]::FromImage($b)
try {
 $g.Clear([Drawing.Color]::FromArgb(245,240,220))
 $g.DrawString('建築ボタン：本番スタイルのCPU比較（実ゲームのスクリーンショットではありません）',$small,$ink,12,8)
 $titles=@('選択中','選択中 ＋ ホバー','未選択 ＋ ホバー')
 for($c=0;$c -lt 3;$c++){$g.DrawString($titles[$c],$font,$ink,130+$c*210,38)}
 $g.DrawString('修正前',$font,$ink,15,81);$g.DrawString('修正後',$font,$ink,15,139)
 $files=@(@('button-before-normal.png','button-before-hover.png','button-before-hover.png'),@('button-after-normal.png','button-after-hover.png','button-unselected-hover.png'))
 for($r=0;$r -lt 2;$r++){for($c=0;$c -lt 3;$c++){
  ImageAt $g $files[$r][$c] (125+$c*210) (78+$r*58)
  $g.DrawString('土壁 · 土5',$font,$ink,165+$c*210,82+$r*58)
 }}
 $g.DrawString('枠と色は実際のStyleBoxTexture設定。文字は比較画像用に別描画。',$small,$ink,12,195)
 $b.Save((Join-Path $dir 'architect-comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
}finally{$g.Dispose();$b.Dispose()}
$b=[Drawing.Bitmap]::new(2240,760);$g=[Drawing.Graphics]::FromImage($b)
try {
 $g.Clear([Drawing.Color]::FromArgb(245,240,220));$g.InterpolationMode='NearestNeighbor';$g.PixelOffsetMode='Half'
 $g.DrawString('岩盤ブロック：同一seed・同一地形条件・同一縮尺のCPU描画比較',$font,$ink,20,12)
 $g.DrawString('修正前：分離した岩棚',$font,$ink,20,44);$g.DrawString('修正後：四方向に連結した岩塊',$font,$ink,1140,44)
 ImageAt $g 'rocks-before.png' 10 78
 ImageAt $g 'rocks-after.png' 1130 78
 $g.DrawString('実ゲームのスクリーンショットではありません。本番の岩接続・正式PNG・周囲の砕石描画を使用。地面シェーダー、樹木、他の物体とHUDは省略。',$small,$ink,20,730)
 $b.Save((Join-Path $dir 'rocks-comparison.png'),[Drawing.Imaging.ImageFormat]::Png)
}finally{$g.Dispose();$b.Dispose();$font.Dispose();$small.Dispose();$ink.Dispose()}
