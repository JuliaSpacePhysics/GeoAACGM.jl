## Performance

`@tullio 𝐫[i] = Yₗₘ[k] * coefs[k, i, j] * alt_powers[j] threads = false` is much faster than something like

```julia
x, y, z = ntuple(3) do i
    sum(1:N) do k
        sum(1:5) do j
            Yₗₘ[k] * coefs[k, i, j] * alt_powers[j]
        end
    end
end
```