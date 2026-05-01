local xmath = require('hfsound/math')

function test_lerp()
    local min = 1
    local max = 5

    assert_roughly_equal(0, xmath.lerp(min, max, -0.25))
    assert_roughly_equal(2, xmath.lerp(min, max, 0.25))
    assert_roughly_equal(4, xmath.lerp(min, max, 0.75))
    assert_roughly_equal(6, xmath.lerp(min, max, 1.25))

    assert_roughly_equal(6, xmath.lerp(max, min, -0.25))
    assert_roughly_equal(4, xmath.lerp(max, min, 0.25))
    assert_roughly_equal(2, xmath.lerp(max, min, 0.75))
    assert_roughly_equal(0, xmath.lerp(max, min, 1.25))
end

function test_lerp_clamped()
    local min = 1
    local max = 5

    assert_roughly_equal(1, xmath.lerp_clamped(min, max, -0.25))
    assert_roughly_equal(2, xmath.lerp_clamped(min, max, 0.25))
    assert_roughly_equal(4, xmath.lerp_clamped(min, max, 0.75))
    assert_roughly_equal(5, xmath.lerp_clamped(min, max, 1.25))
end

function test_ilerp()
    for i = 1, 20 do
        for j = i, i + 20 do
            for k = i - 10, j + 10 do
                local a, b = i, j
                if j % 2 == 0 then
                    a, b = j, i
                end
                local ratio = xmath.ilerp(a, b, k)
                local recovered = xmath.lerp(a, b, ratio)
                assert_roughly_equal(k, recovered)
            end
        end
    end
end

function test_linear_projection()
    for i = -10, 20 do
        
        assert_roughly_equal(i / 10.0, xmath.linear_projection(1, 0, 1, 0, i / 10))
        assert_roughly_equal(i / 10.0, xmath.linear_projection(0, 1, 0, 1, i / 10))
        assert_roughly_equal(i + 2, xmath.linear_projection(2, 12, 0, 1, i / 10))
        assert_roughly_equal(50 - 2 * i, xmath.linear_projection(50, 30, 0, 1, i / 10))

        if i < 0 then
            assert_roughly_equal(0, xmath.linear_projection_clamped(1, 0, 1, 0, i / 10))
            assert_roughly_equal(0, xmath.linear_projection_clamped(0, 1, 0, 1, i / 10))
        elseif i > 10 then
            assert_roughly_equal(1, xmath.linear_projection_clamped(1, 0, 1, 0, i / 10))
            assert_roughly_equal(1, xmath.linear_projection_clamped(0, 1, 0, 1, i / 10))
        else
            assert_roughly_equal(i / 10.0, xmath.linear_projection_clamped(1, 0, 1, 0, i / 10))
            assert_roughly_equal(i / 10.0, xmath.linear_projection_clamped(0, 1, 0, 1, i / 10))
        end
    end

    assert_roughly_equal(0.25, xmath.linear_projection(0, 1, 1, 0, 0.75))
    assert_roughly_equal(5, xmath.linear_projection(0, 10, 0, 1, 0.5))
    assert_roughly_equal(0, xmath.linear_projection(-10, 10, 0, 1, 0.5))
    assert_roughly_equal(-5, xmath.linear_projection(-10, 10, 0, 1, 0.25))
    assert_roughly_equal(0.25, xmath.linear_projection_clamped(0, 1, 1, 0, 0.75))
    assert_roughly_equal(5, xmath.linear_projection_clamped(0, 10, 0, 1, 0.5))
end
