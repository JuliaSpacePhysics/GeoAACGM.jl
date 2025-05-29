using PrecompileTools: @compile_workload

function workload()
    dt = DateTime(2020, 1, 1)
    geoc2aacgm(45.5, -23.5, 1000, dt)
end

@compile_workload begin
    workload()
end
