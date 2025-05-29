using PrecompileTools: @setup_workload, @compile_workload

@setup_workload begin
    dt = DateTime(2020, 1, 1)
    @compile_workload begin
        set_coefficients!(dt)
        geoc2aacgm(45.5, -23.5, 1000)
    end
end
