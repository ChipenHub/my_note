这段代码的含义

```c
void EventLoop::loop() {
looping_ = true;
quit_ = false;

LOG_INFO("Eventloop %p start looping \n", this);

while (!quit_) {

    activeChannels_.clear();
    pollReturnTime_ = poller_->poll(KPollerTimeMs, &activeChannels_);
    for (Channel *channel : activeChannels_) {
        // poller can observe which channels' events happened, and tell eventloopo
        channel->handleEvent(pollReturnTime_);
    }
    // execute callback operation that needed by current Eventloop
    doPendingFunctors();

}

LOG_INFO("Eventloop %p stop looping.\n", this);
looping_ = false;
}
```
