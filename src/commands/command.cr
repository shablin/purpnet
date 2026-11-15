module CLI
    abstract class Command
        def self.run(*args, **kwargs)
            new.run(*args, **kwargs)
        end
    end
end