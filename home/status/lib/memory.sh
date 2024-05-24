#!/usr/bin/env bash

awk '
/^MemTotal:/ {
	mem_total=$2
}
/^MemFree:/ {
	mem_free=$2
}
/^Buffers:/ {
	mem_free+=$2
}
/^Cached:/ {
	mem_free+=$2
}
/^SwapTotal:/ {
	swap_total=$2
}
/^SwapFree:/ {
	swap_free=$2
}
END {
	swap_used=(swap_total-swap_free)/1024/1024
	swap_free=swap_free/1024/1024
	swap_total=swap_total/1024/1024

	free=mem_free/1024/1024
	used=(mem_total-mem_free)/1024/1024
	total=mem_total/1024/1024

	swap_pct=0
	if (swap_total > 0) {
		swap_pct=swap_used/swap_total*100
	}

	pct=0
	if (total > 0) {
		pct=used/total*100
	}

	printf(" %.f%%(%.f%%)\n", pct, swap_pct)
}
' /proc/meminfo
