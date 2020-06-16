local Queue = class("Queue")

function Queue:ctor()
    self.queue_ = {}
end

function Queue:push(...)
    table.insert(self.queue_, {...})
    return self
end

function Queue:pop()
    if not self.queue_[1] then
        return
    end
    return table.remove(self.queue_, 1)
end

function Queue:clear()
    self.queue_ = {}
    return self
end

function Queue:empty()
    return #self.queue_ == 0
end

return Queue