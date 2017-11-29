#!/bin/bash

run_test() {
  ffmpeg=$1
  output=$2
  suffix="signalstats,format=yuv420p,scale=-1:-1:in_range=mpeg,format=rgb24"
  for bits in 8 10 12; do
    ${ffmpeg} -i data/yuv444p${bits}.mp4 \
      -vf scale=-1:-1:in_range=jpeg:out_range=mpeg,${suffix} \
      -y ${output}/yuv444p${bits}_unscaled_jpeg_mpeg.png
    ${ffmpeg} -i data/yuv444p${bits}.mp4 \
      -vf scale=-1:-1:out_range=mpeg,${suffix} \
      -y ${output}/yuv444p${bits}_unscaled_unspec_mpeg.png
    ${ffmpeg} -i data/yuv444p${bits}.mp4 \
      -vf scale=-1:-1,${suffix} \
      -y ${output}/yuv444p${bits}_unscaled_unspec_unspec.png
    
    ${ffmpeg} -i data/yuv444p${bits}.mp4 \
      -vf scale=-1:128:in_range=jpeg:out_range=mpeg,${suffix} \
      -y ${output}/yuv444p${bits}_scaled_jpeg_mpeg.png
    ${ffmpeg} -i data/yuv444p${bits}.mp4 \
      -vf scale=-1:128:out_range=mpeg,${suffix} \
      -y ${output}/yuv444p${bits}_scaled_unspec_mpeg.png
    ${ffmpeg} -i data/yuv444p${bits}.mp4 \
      -vf scale=-1:128,format=yuv420p,${suffix} \
      -y ${output}/yuv444p${bits}_scaled_unspec_unspec.png
  done
}

build_report() {
  old_dir=$1
  new_dir=$2
  for bit in 8 10; do
    echo '<div style="clear:both;">'
    echo " <h3>Bit depth ${bit}</h3>"
    for scale in _scaled _unscaled; do
      echo '<div style="clear:both;">'
      echo "<b>${scale}</b>";
      for i in ${old_dir}/*${bit}${scale}*.png; do
        echo "<div style=\"clear:both; padding-top: 20px;\">"
        composite $i ${i/old/new} -compose difference ${i/old/diff}
        mogrify  -level 0,10000,0.9 ${i/old/diff}
        name=$(basename $i)
        echo '<div style="float:left;">'
        echo " <p>Old (${name})</p>"
        echo " <img src=\"$i\" width=\"600\" align=\"left\"></img>";
        echo '</div>'
        echo '<div style="float:left;">'
        echo " <p>Diff (old-new) ${name}</p>"
        echo " <img src=\"${i/old/diff}\" width=\"600\" align=\"left\"></img>";
        echo '</div>'
        echo '<div style="float:left;">'
        echo " <p>With patch (${name})</p>"
        echo " <img src=\"${i/old/new}\" width=\"600\" align=\"left\"></img>";
        echo '</div>'
      done
      echo '</div>'
    done
    echo '</div>'
  done
}

mkdir -p results/{new,old,diff}

run_test ./ffmpeg results/new
run_test ./ffmpeg_old results/old

cd results
build_report old new > report.html
