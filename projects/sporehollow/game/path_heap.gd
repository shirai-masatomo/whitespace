extends RefCounted
## Stable min-heap: preserve the previous frontier's insertion-order tie break.
static func before(a,b):return a[1]<b[1] or (a[1]==b[1] and a[2]<b[2])
static func push(heap:Array,row:Array):
	heap.append(row);var i=heap.size()-1
	while i>0:
		var parent=(i-1)/2
		if not before(heap[i],heap[parent]):break
		var other=heap[parent];heap[parent]=heap[i];heap[i]=other;i=parent
static func pop(heap:Array)->Array:
	var result=heap[0];var last=heap.pop_back()
	if heap.is_empty():return result
	heap[0]=last;var i=0
	while i*2+1<heap.size():
		var child=i*2+1
		if child+1<heap.size() and before(heap[child+1],heap[child]):child+=1
		if not before(heap[child],heap[i]):break
		var other=heap[i];heap[i]=heap[child];heap[child]=other;i=child
	return result
